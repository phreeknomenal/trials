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

  # Similar studies are not in here. The board puts "Other studies you match"
  # in this column as a compact list; SimilarTrialsComponent is a full-width
  # three-column grid with its own heading, so it stays a section at the end of
  # the main column until someone builds the narrow variant.
  def initialize(study:, nct_id:)
    @study = study
    @nct_id = nct_id
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
