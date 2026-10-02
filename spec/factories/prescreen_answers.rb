FactoryBot.define do
  factory :prescreen_answer do
    user
    sequence(:nct_id) { |n| "NCT#{n.to_s.rjust(8, "0")}" }
    question_key { "q-0" }
    answer { PrescreenAnswer::YES }
  end
end
