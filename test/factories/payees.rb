FactoryBot.define do
  factory :payee do
    association :user
    name { Faker::Company.name }
  end
end
