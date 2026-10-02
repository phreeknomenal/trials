# The study's own eligibility criteria, asked as questions a person answers
# about themselves. Answers sort criteria in the panel above; they never move
# the match score, and the copy says so.
#
# Public to read, signed-in to answer, because answers are health information
# kept on an account. Writing the questions is the paid step, behind a button
# rather than on page load, so a crawler walking study pages spends nothing.
class Page::Trials::PrescreenComponent < ApplicationComponent
  ANSWER_LABELS = {
    PrescreenAnswer::YES => "Yes",
    PrescreenAnswer::NO => "No",
    PrescreenAnswer::UNSURE => "Not sure"
  }.freeze

  BUTTON_SIZE = "px-3 py-1.5 text-sm".freeze

  attr_reader :nct_id, :study, :prescreen, :answers

  def initialize(nct_id:, study:, prescreen:, current:, answers:, signed_in:)
    @nct_id = nct_id
    @study = study
    @prescreen = prescreen
    @current = current
    @answers = answers
    @signed_in = signed_in
  end

  def render? = StudyPrescreen.criteria?(study)

  def signed_in? = @signed_in

  def state
    @state ||= if prescreen.nil?
      :none
    elsif prescreen.completed? && !@current
      :outdated
    elsif prescreen.completed?
      questions.any? ? :ready : :nothing_to_ask
    elsif prescreen.failed? || prescreen.stale?
      :failed
    else
      :pending
    end
  end

  def questions = @questions ||= prescreen.question_list

  def answered_count = questions.count { |question| answers.key?(question.key) }

  def answer_for(question) = answers[question.key]

  def button_classes(selected)
    Buttons::ButtonStyles.classes(selected ? "primary" : "secondary", size: BUTTON_SIZE)
  end

  def write_button_label
    (state == :outdated) ? "Update the questions" : "Answer a few questions"
  end

  def stream_name = "study_prescreen_#{nct_id}"

  def target_id = "study-prescreen-#{nct_id}"
end
