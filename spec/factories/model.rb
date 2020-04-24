FactoryBot.define do
  factory :model, class: Model do
    value { Faker::Name.first_name }
  end
end
