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
      return redirect_back_or_to search_path(nct_id), status: :see_other,
        alert: "That question is no longer on this study. The questions may have been updated."
    end

    if PrescreenAnswer.record(user: current_user, nct_id: nct_id, question_key: question_key, answer: params[:answer].to_s)
      redirect_back_or_to search_path(nct_id), status: :see_other
    else
      redirect_back_or_to search_path(nct_id), status: :see_other,
        alert: "Answers can be yes, no, or not sure."
    end
  end
end
