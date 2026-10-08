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
    meal_plan: MealPlanSets
    human_feedback: str
    final_response: str


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


def get_missing_data_node(state: State) -> State:
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

            Ask the user for any missing information. Be concise and friendly.
            """
        ),
    ]
    response = llm.invoke(messages)
    state["missing_data"] = response
    return state


def get_human_feedback_node(state: State) -> State:
    llm = ChatOpenAI(model="gpt-5-mini", temperature=0)
    meal_plans = state["meal_plan"]
    messages = [
        SystemMessage(
            content=f"""
            Get user's feedback to check if the user is satisfied with the generated meal plan. Be concise and friendly.

            Generated meal plans: {meal_plans}
            
            Ask the user for feedback and if they are satisfied return 'approve'.
            """
        )
    ]
    response = llm.invoke(messages)
    state["human_feedback"] = response
    return state


def generate_mealplan_node(state: State) -> State:
    llm = ChatOpenAI(model="gpt-5-mini", temperature=0)
    # Use structured output without tools binding - tools don't work well with structured output
    structured_llm = llm.with_structured_output(MealPlanSets)
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
            - List of ingredients

            Return the meals in a list format with the structure: plans array containing 3 MealPlanSet objects.
            Each meal should have distinct dishes and ingredients."""
        )
    ]
    response = structured_llm.invoke(messages)
    state["meal_plan"] = response
    return state


def finalize_response_node(state: State) -> State:
    llm = ChatOpenAI(model="gpt-5-mini", temperature=0)
    messages = [
        SystemMessage(
            content=f"""
            Conclude the response to finalize. Keep it simple and short.
            
            The final result: 
            - Meal plan: {state['meal_plan']}
            - Feedback: {state['human_feedback']}
        """
        )
    ]

    response = llm.invoke(messages)
    state["final_response"] = response
    return state


def should_get_missing_data(state: State) -> str:
    if state["meal_provided_info"].has_all_details:
        return "generate_meal_plan"
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
builder.add_node("generate_meal_plan", generate_mealplan_node)
builder.add_node("get_human_feedback", get_human_feedback_node)
builder.add_node("finalize_response", finalize_response_node)

builder.add_edge(START, "gather_meal_info")
builder.add_conditional_edges(
    "gather_meal_info",
    should_get_missing_data,
    {
        "get_missing_data": "get_missing_data",
        "generate_meal_plan": "generate_meal_plan",
    },
)
builder.add_edge("get_missing_data", END)
builder.add_edge("generate_meal_plan", "get_human_feedback")
builder.add_conditional_edges(
    "get_human_feedback",
    decide_next_step,
    {
        "approve": "finalize_response",
        "revise": "generate_meal_plan",
    },
)
builder.add_edge("finalize_response", END)

workflow = builder.compile()

# print(
#     workflow.invoke(
#         {"input": "I want to eat a healthy meal with chicken and vegetables"}
#     )
# )


@app.route("/chat-agent", methods=["POST"])
def chat_agent():
    try:
        data = request.json
        input = data.get("input")

        if not input:
            return jsonify({"error": "Input is required"}), 400

        response = workflow.invoke({"input": input})

        print("Workflow response:", response)

        # Extract missing_data content if it's a message object
        missing_data_str = ""
        if response.get("missing_data"):
            missing_data_obj = response["missing_data"]
            # If it's a LangChain message, extract the content
            if hasattr(missing_data_obj, "content"):
                missing_data_str = missing_data_obj.content
            else:
                missing_data_str = str(missing_data_obj)

        # Convert Pydantic models to dictionaries for JSON serialization
        serializable_response = {
            "meal_provided_info": (
                response["meal_provided_info"].model_dump()
                if response.get("meal_provided_info")
                else None
            ),
            "missing_data": missing_data_str if missing_data_str else None,
            "meal_plan_sets": (
                response["meal_plan"].model_dump()
                if response.get("meal_plan")
                else None
            ),
            "final_response": response.get("final_response"),
        }

        return jsonify(serializable_response)
    except Exception as e:
        import traceback
        print(f"Error in chat_agent: {e}")
        traceback.print_exc()
        return jsonify({"error": "An unexpected error occurred. Please try again."}), 500


if __name__ == "__main__":
    app.run(debug=True)
