FactoryBot.define do
  factory :income do
    association :user
    description { Faker::Job.title }
    amount { 3000.00 }
    date { Date.current }
    income_type { "salary" }
    recurring { false }
    recurrence_day { nil }
  end
end
