# The right sidebar on a study, from the board: what to do next, what happens
# after that, and the other studies you match.
#
# The board's primary button is "Send my details". **The app does not do that
# and is not going to.** It says so on the About page ("Nothing about you
# reaches a study team through this app"), on the privacy policy ("You choose
# the study and you make contact"), and in the FAQ. A button here that implied
# otherwise would make three other pages into lies.
#
# So the next step is the coordinator's own contact details, which the registry
# publishes and the app already stores, and the copy says plainly that the
# person makes the contact themselves.
class Page::Trials::NextStepComponent < ApplicationComponent
  # Generic and true. The registry does not publish a study's own process, so
  # this describes what contacting a team is like rather than what this team
  # will do, and says so.
  WHAT_HAPPENS = [
    "You get in touch with the coordinator using the details above.",
    "They ask about your history, usually by phone, to check the criteria a profile cannot.",
    "If it fits, they book a screening visit and explain what the study involves."
  ].freeze

  attr_reader :study, :nct_id

  def initialize(study:, nct_id:, similar_trials: nil)
    @study = study
    @nct_id = nct_id
    @similar_trials = similar_trials
  end

  # Two at most. The board shows two, and this is a column beside the study
  # somebody is reading: a third turns a suggestion into a list to work through.
  def similar_trials = Array(@similar_trials).first(2)

  def similar_trials? = similar_trials.any?

  def score_for(trial) = trial[:match_score] || trial["match_score"]

  def nct_for(trial) = trial[:nct_id] || trial["nct_id"]

  def title_for(trial) = trial[:title] || trial["title"]

  # Phase and study type, which is what the registry gives. The board's version
  # reads "11 mi · Phase 3"; there is no distance anywhere in the data.
  def meta_for(trial)
    [
      helpers.humanize_registry_value(trial[:phase] || trial["phase"]).presence,
      helpers.humanize_registry_value(trial[:study_type] || trial["study_type"]).presence
    ].compact.join(" · ")
  end

  def contacts
    Array(study[:central_contacts]).select { |c| c[:name].present? || c[:email].present? || c[:phone].present? }
  end

  def contacts? = contacts.any?

  # The registry's own page, which is the fallback when no contact is published:
  # it always exists, and it is where a coordinator's details would appear if
  # they were ever added.
  def registry_url = "https://clinicaltrials.gov/study/#{nct_id}"
end
