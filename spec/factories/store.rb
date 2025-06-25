FactoryBot.define do
  factory :store do
    api_url { "https://random-url.com" }
    consumer_key { "random-key123" }
    consumer_secret { "random-secret123" }
    user
  end
end
