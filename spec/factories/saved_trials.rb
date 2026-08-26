FactoryBot.define do
  factory :saved_trial do
    user
    sequence(:nct_id) { |n| "NCT#{n.to_s.rjust(8, "0")}" }
    trial_title { "A clinical trial" }
    status { SavedTrial::INTERESTED }
  end
end
