from flask import Flask, jsonify, request
import stripe
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
PUBLISHABLE_KEY = os.getenv("STRIPE_PUBLISHABLE_KEY")


@app.route("/create-checkout-session", methods=["POST"])
def create_checkout_session():
    domain_url = "http://127.0.0.1:4242/"
    data = request.json or {}
    price_id = data.get("priceId")
    user_id = data.get("userId")
    if not price_id or not user_id:
        return jsonify({"error": "priceId and userId are required"}), 400
    try:
        session = stripe.checkout.Session.create(
            payment_method_types=["card"],
            mode="subscription",
            line_items=[
                {
                    "price": price_id,
                    "quantity": 1,
                }
            ],
            metadata={"user_id": user_id},
            success_url=domain_url + "success?session_id={CHECKOUT_SESSION_ID}",
            cancel_url=domain_url + "cancelled",
        )
        return jsonify({"url": session.url})
    except stripe.error.StripeError as e:
        print(f"Stripe error in create_checkout_session: {e}")
        return jsonify({"error": "Failed to create checkout session. Please try again."}), 400
    except Exception as e:
        print(f"Error in create_checkout_session: {e}")
        return jsonify({"error": "An unexpected error occurred."}), 500


endpoint_secret = os.getenv("ENDPOINT_SECRET")


@app.route("/webhook", methods=["POST"])
def stripe_webhook():
    payload = request.data
    sig_header = request.headers.get("Stripe-Signature")
    endpoint_secret = "whsec_a9af295abb6d9cd18bd999eac86cf9695bba766770e56bfc8571ff535fbc9f05"  # From Stripe Dashboard

    try:
        event = stripe.Webhook.construct_event(payload, sig_header, endpoint_secret)
    except Exception as e:
        return str(e), 400

    if event["type"] == "checkout.session.completed":
        session = event["data"]["object"]
        customer_email = session["customer_details"]["email"]
        user_id = session.get("metadata", {}).get("user_id")
        print(f"Checkout completed for user_id={user_id}, email={customer_email}")
        # TODO: Update user subscription status in Supabase

    elif event["type"] == "invoice.payment_failed":
        invoice = event["data"]["object"]
        customer_id = invoice.get("customer")
        print(f"Payment failed for customer={customer_id}")
        # TODO: Update subscription status in Supabase and notify user

    return "", 200


@app.route("/payment-sheet", methods=["POST"])
def payment_sheet():
    try:
        # Use an existing Customer ID if this is a returning customer
        userId = request.args.get("user_id")
        if not userId:
            return jsonify({"error": "user_id is required"}), 400

        customer = stripe.Customer.create(metadata={"user_id": userId})
        ephemeralKey = stripe.EphemeralKey.create(
            customer=customer["id"],
            stripe_version="2025-08-27.basil",
        )

        paymentIntent = stripe.PaymentIntent.create(
            amount=699,
            currency="eur",
            customer=customer["id"],
        )

        return jsonify(
            paymentIntent=paymentIntent.client_secret,
            ephemeralKey=ephemeralKey.secret,
            customer=customer.id,
            publishableKey=PUBLISHABLE_KEY,
        )
    except stripe.error.StripeError as e:
        print(f"Stripe error in payment_sheet: {e}")
        return jsonify({"error": "Failed to initialize payment. Please try again."}), 400
    except Exception as e:
        print(f"Error in payment_sheet: {e}")
        return jsonify({"error": "An unexpected error occurred."}), 500


if __name__ == "__main__":
    app.run(port=4242)
