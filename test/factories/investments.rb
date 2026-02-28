FactoryBot.define do
  factory :investment do
    association :user
    name { Faker::Company.name }
    ticker { Faker::Alphanumeric.alpha(number: 4).upcase }
    investment_type { "stock" }
    quantity { 10.0 }
    average_price { 100.0 }
    current_price { 120.0 }
    currency { "BRL" }
  end
end
