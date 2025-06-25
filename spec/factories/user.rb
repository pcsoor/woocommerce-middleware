FactoryBot.define do
  sequence :email do |n|
    "user#{n}@example.com"
  end

  factory :user do
    email
    password { "123qwe" }

    trait :with_store do
      after(:create) do |user|
        create(:store, user: user)
      end
    end
  end
end
