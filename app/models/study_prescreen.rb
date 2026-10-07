# == Schema Information
#
# Table name: study_prescreens
#
#  id              :bigint           not null, primary key
#  criteria_digest :string
#  error_message   :text
#  generated_at    :datetime
#  questions       :jsonb            not null
#  status          :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  nct_id          :string           not null
#
# Indexes
#
#  index_study_prescreens_on_nct_id  (nct_id) UNIQUE
#
class StudyPrescreen < ApplicationRecord
  include GeneratedPerStudy

  # Past a dozen, a form stops being something a person finishes.
  MAX_QUESTIONS = 12

  SIDES = %w[inclusion exclusion].freeze

  # qualifying_answer is the answer that keeps someone in. An exclusion
  # criterion phrased "Have you had chemotherapy in the last 6 months?"
  # qualifies on "no". The generator sets it, and nothing infers it from the
  # wording, because "yes" is the right answer to half the questions.
  #
  # source is the study's own sentence, shown under the question. A question is
  # a paraphrase and the patient is owed the original.
  Question = Data.define(:key, :text, :source, :side, :qualifying_answer) do
    def qualifies?(answer) = answer == qualifying_answer

    def disqualifies?(answer) = PrescreenAnswer::DECIDED.include?(answer) && !qualifies?(answer)
  end

  def self.digest_for(study)
    Digest::SHA256.hexdigest("#{study[:inclusion_criteria]}\n--exclusion--\n#{study[:exclusion_criteria]}")
  end

  def self.criteria?(study)
    study[:inclusion_criteria].present? || study[:exclusion_criteria].present?
  end

  # Written from the criteria the study holds now. A prescreen written from an
  # earlier version is treated as absent rather than shown.
  def current_for?(study)
    completed? && criteria_digest == self.class.digest_for(study)
  end

  def question_list
    questions.map { |question| Question.new(**question.symbolize_keys.slice(*Question.members)) }
  end
end
