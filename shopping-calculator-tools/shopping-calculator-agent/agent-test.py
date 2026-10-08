from dataclasses import dataclass
from typing_extensions import TypedDict, Literal
from langgraph.graph import StateGraph, START, END
from typing import Annotated, List
from dotenv import load_dotenv
import os
from pydantic import BaseModel, Field
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI
from langchain_tavily import TavilySearch
from flask import Flask, request, jsonify
from langgraph.types import Command, interrupt
from langgraph.checkpoint.memory import MemorySaver


load_dotenv()

app = Flask(__name__)

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
search_tool = TavilySearch(max_results=3)


# meal info model
class MealInfo(BaseModel):
    has_all_details: bool = Field(
        description="Whether the meal information is complete"
    )
    meal_goal: str = Field(description="what the user wants to eat")
    ingredients: str = Field(
        description="if the user has priority to consume ingredients"
    )
    preferences: str = Field(
        description="if the user is on diet, mood to eat certain dishes, etc."
    )


# meal plan model
class MealPlanSet(BaseModel):
    meal: str = Field(description="The meal type (breakfast, lunch, or dinner)")
    plate: str = Field(description="The plate/dish name for the meal")
    ingredients: List[str] = Field(description="The ingredients for the meal")


class MealPlanSets(BaseModel):
    plans: List[MealPlanSet] = Field(
        description="List of meal plans for breakfast, lunch, and dinner"
    )


# graph state
class State(TypedDict):
    input: str
    meal_provided_info: MealInfo
    missing_data: str
    meal_plan_proposal: str
    meal_plan: MealPlanSets
    human_feedback: str
    resume_input: str


# nodes
def gather_meal_info_node(state: State) -> State:
    llm = ChatOpenAI(model="gpt-5-mini", temperature=0)
    structured_llm = llm.with_structured_output(MealInfo)
    messages = [
        SystemMessage(
            content="""
          You are an assistant that gathers key details for meal plans.

          Look through the conversation to extract:
          1. Meal goal (what the user wants to eat)
          2. Ingredients to consume (if the user has priority to consume ingredients)
          3. Preferences (if the user is on diet, mood to eat certain dishes, etc.).
        """
        ),
        HumanMessage(content=state["input"]),
    ]
    response = structured_llm.invoke(messages)
    state["meal_provided_info"] = response
    return state


def get_missing_data_node(state: State):
    llm = ChatOpenAI(model="gpt-5-mini", temperature=0)
    meal_info = state["meal_provided_info"]
    messages = [
        SystemMessage(
            content=f"""
            Collect missing data from the user.

            Current information:
            - Meal Goal: {meal_info.meal_goal}
            - Ingredients: {meal_info.ingredients}
            - Preferences: {meal_info.preferences}

            Create a friendly, conversational question asking for the missing information.
            Be specific and helpful. List out what you need to know.
            Keep it concise but simple and informative.
        """
        ),
    ]
    response = llm.invoke(messages)
    print("missing data question", response)

    user_response = interrupt({"question": response.content})

    state["missing_data"] = response
    return Command(goto="gather_meal_info", update={"input": user_response})


def get_approval_node(
    state: State,
) -> Command[Literal["generate_meal_plan", "get_human_feedback"]]:

    is_approved = interrupt(
        {
            "question": "Are you ok with these meal plans?",
            "proposal": state["meal_plan_proposal"],
        }
    )

    if is_approved:
        return Command[str](goto="generate_meal_plan")
    else:
        return Command(goto="get_human_feedback")


def get_human_feedback_node(
    state: State,
):
    feedback = interrupt(
        "Tell me what you didn't love about the last plan so I can give you a better one!",
    )

    return Command(goto="propose_meal_plan", update={"human_feedback": feedback})


def propose_mealplan_node(state: State) -> State:
    llm = ChatOpenAI(model="gpt-5-mini", temperature=0)
    messages = [
        SystemMessage(
            content=f"""
            Create a tailored meal plan for the user.

            Details:
            - Meal Goal: {state['meal_provided_info'].meal_goal}
            - Ingredients: {state['meal_provided_info'].ingredients}
            - Preferences: {state['meal_provided_info'].preferences}
            - Feedback: {state['human_feedback']}

            Provide exactly 3 meals (breakfast, lunch, dinner) with:
            - Meal name (must be one of: breakfast, lunch, dinner)
            - Plate/dish name

            Return a message about tailored meals suggeting meal name with plate/dish name in a formatted way.
            Each meal should have distinct dishes and ingredients."""
        )
    ]

    response = llm.invoke(messages)
    state["meal_plan_proposal"] = response
    return state


def generate_mealplan_node(state: State) -> State:
    llm = ChatOpenAI(model="gpt-5-mini", temperature=0)
    # Use structured output without tools binding - tools don't work well with structured output
    structured_llm = llm.with_structured_output(MealPlanSets)
    messages = [
        SystemMessage(
            content=f"""
            Format the tailored meal plan based on the final meal plan. 
            They have to be consistent.

            Details:
            - Final meal plan: {state['meal_provided_info'].meal_goal}

            Provide exactly 3 meals (breakfast, lunch, dinner) with:
            - Meal name (must be one of: breakfast, lunch, dinner)
            - Plate/dish name
            - List of ingredients

            Return the meals in a list format with the structure: plans array containing 3 MealPlanSet objects.
            Each meal should have distinct dishes and ingredients."""
        )
    ]
    response = structured_llm.invoke(messages)
    state["meal_plan"] = response
    return state


def should_get_missing_data(state: State) -> str:
    if state["meal_provided_info"].has_all_details:
        return "propose_meal_plan"
    else:
        return "get_missing_data"


def decide_next_step(state: State) -> Literal["revise", "finalize"]:
    if state["human_feedback"].lower() == "approve":
        return "finalize"
    else:
        return "revise"


# state builder
builder = StateGraph(State)

builder.add_node("gather_meal_info", gather_meal_info_node)
builder.add_node("get_missing_data", get_missing_data_node)
builder.add_node("get_approval", get_approval_node)
builder.add_node("get_human_feedback", get_human_feedback_node)
builder.add_node("propose_meal_plan", propose_mealplan_node)
builder.add_node("generate_meal_plan", generate_mealplan_node)


builder.add_edge(START, "gather_meal_info")
builder.add_conditional_edges(
    "gather_meal_info",
    should_get_missing_data,
    {
        "get_missing_data": "get_missing_data",
        "propose_meal_plan": "propose_meal_plan",
    },
)
builder.add_edge("get_missing_data", END)
builder.add_edge("propose_meal_plan", "get_approval")
builder.add_edge("generate_meal_plan", END)

checkpointer = MemorySaver()

workflow = builder.compile(checkpointer=checkpointer)


# print(
#     workflow.invoke(
#         {"input": "I want to eat a healthy meal with chicken and vegetables"}
#     )
# )


@app.route("/chat-agent-test", methods=["POST"])
def chat_agent():
    try:
        data = request.json
        input = data.get("input")
        userid = data.get("userid")
        resume_input = data.get("resume_input")

        if not input:
            return jsonify({"error": "Input is required"}), 400

        if not userid:
            return jsonify({"error": "User ID is required"}), 400

        config = {"configurable": {"thread_id": userid}}

        if resume_input is not None:
            print(f"Resuming workflow for user {userid} with value: {resume_input}")
            response = workflow.invoke(Command(resume=resume_input), config=config)
        else:
            response = workflow.invoke({"input": input}, config=config)

        if "__interrupt__" in response:
            interrupt_data = response["__interrupt__"]

            # Extract state for frontend
            state_data = {
                "meal_provided_info": (
                    response["meal_provided_info"].model_dump()
                    if response.get("meal_provided_info")
                    else None
                ),
                "missing_data": response.get("missing_data"),
                "meal_plan_proposal": response.get("meal_plan_proposal"),
                "human_feedback": response.get("human_feedback"),
            }

            return jsonify(
                {
                    "status": "interrupted",
                    "interrupt": interrupt_data,  # Contains question and/or proposal
                    "state": state_data,
                }
            )
        # Extract missing_data content if it's a message object
        missing_data_str = ""
        if response.get("missing_data"):
            missing_data_obj = response["missing_data"]
            # If it's a LangChain message, extract the content
            if hasattr(missing_data_obj, "content"):
                missing_data_str = missing_data_obj.content
            else:
                missing_data_str = str(missing_data_obj)

        print("workflow completed")

        # Convert Pydantic models to dictionaries for JSON serialization
        serializable_response = {
            "meal_provided_info": (
                response["meal_provided_info"].model_dump()
                if response.get("meal_provided_info")
                else None
            ),
            "missing_data": missing_data_str if missing_data_str else None,
            "meal_plan_proposal": response.get("meal_plan_proposal"),
            "meal_plan_sets": (
                response["meal_plan"].model_dump()
                if response.get("meal_plan")
                else None
            ),
        }

        return jsonify(serializable_response)
    except Exception as e:
        import traceback
        print(f"Error in chat_agent: {e}")
        traceback.print_exc()
        return jsonify({"error": "An unexpected error occurred. Please try again."}), 500


if __name__ == "__main__":
    app.run(debug=True)
