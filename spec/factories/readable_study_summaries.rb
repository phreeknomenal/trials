# == Schema Information
#
# Table name: readable_study_summaries
#
#  id            :bigint           not null, primary key
#  content       :text
#  error_message :text
#  generated_at  :datetime
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  nct_id        :string           not null
#
# Indexes
#
#  index_readable_study_summaries_on_nct_id  (nct_id) UNIQUE
#
FactoryBot.define do
  factory :readable_study_summary do
    sequence(:nct_id) { |n| "NCT#{format("%08d", n)}" }
    status { ReadableStudySummary::PENDING }

    trait :completed do
      status { ReadableStudySummary::COMPLETED }
      content { "A plain-language summary that anyone can understand." }
      generated_at { Time.current }
    end

    trait :failed do
      status { ReadableStudySummary::FAILED }
      error_message { "Something went wrong while generating the summary." }
    end
  end
end
