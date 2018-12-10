Rails.configuration.stripe = {
  :publishable_key => "pk_test_cE3OBnOzvrGei8oQd6qiC5iB",
  :secret_key      => "sk_test_OX0paeNt8e66o4BkRGzHxrhu"
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]