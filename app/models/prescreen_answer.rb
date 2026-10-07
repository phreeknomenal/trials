# == Schema Information
#
# Table name: prescreen_answers
#
#  id           :bigint           not null, primary key
#  answer       :string           not null
#  question_key :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  nct_id       :string           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_prescreen_answers_on_user_id              (user_id)
#  index_prescreen_answers_on_user_study_question  (user_id,nct_id,question_key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class PrescreenAnswer < ApplicationRecord
  YES = "yes".freeze
  NO = "no".freeze
  UNSURE = "unsure".freeze

  ANSWERS = [YES, NO, UNSURE].freeze

  # The two that settle a criterion. "Not sure" leaves it with the study team.
  DECIDED = [YES, NO].freeze

  belongs_to :user

  validates :nct_id, presence: true, format: {with: GeneratedPerStudy::NCT_ID_FORMAT}
  validates :question_key, presence: true, uniqueness: {scope: [:user_id, :nct_id]}
  validates :answer, presence: true, inclusion: {in: ANSWERS}

  # One statement, INSERT ... ON CONFLICT DO UPDATE, rather than find then
  # save. Two first answers to the same question can arrive together (Yes, then
  # No, clicked quickly: two forms, two requests). Find-then-save let both see
  # no row; the second then failed the uniqueness validation or hit the unique
  # index and raised. Here the later write simply wins, which is the answer the
  # person meant.
  #
  # upsert skips validations, so the answer is checked first. False means the
  # answer was not one of ANSWERS and nothing was written.
  def self.record(user:, nct_id:, question_key:, answer:)
    return false unless ANSWERS.include?(answer)

    upsert(
      {user_id: user.id, nct_id: nct_id, question_key: question_key, answer: answer},
      unique_by: %i[user_id nct_id question_key],
      update_only: [:answer]
    )
    true
  end

  # question_key => answer, for one person and one study.
  def self.for(user, nct_id)
    return {} unless user

    where(user: user, nct_id: nct_id).pluck(:question_key, :answer).to_h
  end
end
