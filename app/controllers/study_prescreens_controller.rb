# Public, behind the same three limits as readable summaries. Writing the
# questions is a paid Claude call per study, and the questions are shared by
# everyone who opens that study.
class StudyPrescreensController < ApplicationController
  include PaidGenerationLimits

  ANONYMOUS_HOURLY_LIMIT = 5
  SIGNED_IN_HOURLY_LIMIT = 30

  def self.daily_limit
    Integer(ENV.fetch("PRESCREEN_DAILY_LIMIT", 200))
  end

  limits_paid_generation anonymous_per_hour: ANONYMOUS_HOURLY_LIMIT,
    signed_in_per_hour: SIGNED_IN_HOURLY_LIMIT

  # Redirects back to the study rather than rendering a stream. The study page
  # refreshes by morphing, so this lands as an in-place update showing the
  # pending state, and the job's broadcast refresh brings the questions.
  def create
    record = StudyPrescreen.find_or_create_pending(nct_id)
    enqueue(record)

    redirect_back_or_to search_path(nct_id), status: :see_other
  end

  private

  def paid_record_class = StudyPrescreen

  def limit_target_id = "study-prescreen-#{nct_id}"

  def limit_noun = "questions"

  def enqueue(record)
    if record.completed?
      # The daily cap waves through studies that already have a row, so a
      # completed one is rewritten only when the registry says its criteria
      # changed. Otherwise a repeated POST would be unmetered paid calls.
      study = ClinicalTrialClient.get_study(nct_id)
      return if study[:error].present? || record.current_for?(study)

      record.update!(status: StudyPrescreen::PENDING, error_message: nil)
    elsif record.failed?
      record.update!(status: StudyPrescreen::PENDING, error_message: nil)
    elsif record.previously_new_record?
      nil
    elsif record.stale?
      record.touch
    else
      return
    end

    GenerateStudyPrescreenJob.perform_later(nct_id)
  end
end
