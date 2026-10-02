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
class ReadableStudySummary < ApplicationRecord
  include GeneratedPerStudy
end
