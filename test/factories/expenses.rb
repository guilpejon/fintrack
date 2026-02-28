FactoryBot.define do
  factory :expense do
    association :user
    association :category
    description { Faker::Commerce.product_name }
    amount { 100.00 }
    date { Date.current }
    expense_type { "variable" }
    recurring { false }
    recurrence_day { nil }
  end
end
