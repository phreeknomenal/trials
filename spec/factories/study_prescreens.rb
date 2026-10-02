FactoryBot.define do
  factory :study_prescreen do
    sequence(:nct_id) { |n| "NCT#{n.to_s.rjust(8, "0")}" }
    status { GeneratedPerStudy::PENDING }

    trait :completed do
      status { GeneratedPerStudy::COMPLETED }
      generated_at { Time.current }
      questions do
        [
          {key: "q-0", text: "Have you been diagnosed with asthma?", source: "Diagnosis of asthma",
           side: "inclusion", qualifying_answer: "yes"},
          {key: "q-1", text: "Do you smoke?", source: "Current smokers",
           side: "exclusion", qualifying_answer: "no"}
        ]
      end
    end
  end
end
