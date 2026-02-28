FactoryBot.define do
  factory :credit_card do
    association :user
    name { "#{Faker::Commerce.department(max: 1, fixed_amount: true)} Card" }
    limit { 5000.00 }
    last4 { Faker::Number.number(digits: 4).to_s }
    brand { "visa" }
    color { "#6C63FF" }
    billing_day { 1 }
    due_day { 10 }
  end
end
