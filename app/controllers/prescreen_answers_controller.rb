# One person's answer to one prescreen question. Self-reported health
# information, so signed-in only, and always written through current_user so
# there is no id to forge.
#
# Redirects back rather than rendering a stream. The study page refreshes by
# morphing with scroll preserved, so an answer lands in place, and the criteria
# panel, the question list and the counts all re-render from one source.
class PrescreenAnswersController < ApplicationController
  before_action :authenticate_user!

  def create
    nct_id = params[:nct_id]
    prescreen = StudyPrescreen.completed.find_by(nct_id: nct_id)
    question_key = params[:question_key].to_s

    # Only keys the study's questions actually have. Anything else would be a
    # row no page ever reads.
    unless prescreen&.question_list&.any? { |question| question.key == question_key }
      return redirect_to search_path(nct_id, anchor: "prescreen"), status: :see_other,
        alert: "That question is no longer on this study. The questions may have been updated."
    end

    answer = current_user.prescreen_answers.find_or_initialize_by(nct_id: nct_id, question_key: question_key)

    if answer.update(answer: params[:answer])
      redirect_to search_path(nct_id, anchor: "prescreen"), status: :see_other
    else
      redirect_to search_path(nct_id, anchor: "prescreen"), status: :see_other,
        alert: "Answers can be yes, no, or not sure."
    end
  end
end
