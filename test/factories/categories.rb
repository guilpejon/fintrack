FactoryBot.define do
  factory :category do
    association :user
    name { Faker::Commerce.department(max: 1, fixed_amount: true) }
    color { "#6C63FF" }
    icon { "home" }
  end
end
