FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "password123" }
    currency { "BRL" }
    locale { "pt-BR" }
  end
end
