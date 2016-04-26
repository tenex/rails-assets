Rails.configuration.stripe = {
  publishable_key: Figaro.env.stripe_publishable_key!,
  secret_key:      Figaro.env.stripe_secret_key!
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
