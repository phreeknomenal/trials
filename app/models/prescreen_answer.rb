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

  # question_key => answer, for one person and one study.
  def self.for(user, nct_id)
    return {} unless user

    where(user: user, nct_id: nct_id).pluck(:question_key, :answer).to_h
  end
end
