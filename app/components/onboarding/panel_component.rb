# The right half of the wizard, answering "why are you asking me this?" for the
# step on the left.
#
# The weights are real: they are TrialScorer::WEIGHTS, the same numbers the
# scorer uses, read rather than restated. Telling someone conditions are the
# largest factor is only worth saying if it is true, and it stops being true the
# moment somebody retunes the scorer and forgets this file.
#
# The design board also shows a live count of how many studies match at 25, 50
# and 100 miles. That needs a registry query per setting on every keystroke, so
# it is not here.
class Onboarding::PanelComponent < ApplicationComponent
  # Which scored criteria each step's answers feed. Steps that feed none say so
  # rather than implying every question changes a score.
  CRITERIA = {
    "identity" => [],
    "basics" => %i[age sex],
    "location" => %i[location],
    "conditions" => %i[conditions],
    "logistics" => %i[location],
    "preferences" => %i[study_type phase_risk],
    "about_you" => []
  }.freeze

  NOTES = {
    "identity" => "Your name, pronouns and photo never leave your account. None of it is sent to a study team, and none of it is part of any score.",
    "basics" => "Age and sex are the two criteria a study can rule you out on outright, rather than merely score you lower for.",
    "location" => "Only the ZIP is stored, never a street address. It decides which sites count as near you.",
    "conditions" => "The largest single factor. Everything else adjusts a ranking; this decides which studies are in it at all.",
    "logistics" => "Distance changes the ranking, not the list. A study further than you would travel drops down rather than disappearing.",
    "preferences" => "Answer only if you have a view. Left blank, these score neutrally rather than against you.",
    "about_you" => "None of this affects matching. It helps studies report who takes part, and connects you with people looking for the same things. You can skip it."
  }.freeze

  # Reference rather than persuasion: the prompt already says to answer only if
  # you have a view.
  PHASES = {
    "Phase 1" => "First tests in people, usually small. Mainly checking safety and dose.",
    "Phase 2" => "Larger. Does the treatment work, and at what dose.",
    "Phase 3" => "Large, compared against current standard care. The step before approval.",
    "Observational" => "No study treatment. Researchers record what happens in ordinary care."
  }.freeze

  attr_reader :step

  def initialize(step:)
    @step = step
  end

  def note = NOTES[step.slug]

  def criteria = CRITERIA.fetch(step.slug, [])

  def scores_anything? = criteria.any?

  # Out of 100, straight from the scorer.
  def weight = criteria.sum { |c| TrialScorer::WEIGHTS.fetch(c, 0) }

  def phases? = step.slug == "preferences"

  def phases = PHASES
end
