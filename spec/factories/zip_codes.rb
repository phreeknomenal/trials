FactoryBot.define do
  factory :zip_code do
    sequence(:zip) { |n| format("%05d", 10000 + n) }
    city { "Birmingham" }
    state { "Alabama" }
  end
end
