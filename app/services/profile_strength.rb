# How much of the profile is doing work, and what is left that would change a
# score.
#
# Only the optional steps that affect matching count. The four required steps are
# behind the onboarding gate, so anyone seeing a dashboard has done them, and
# reporting them as progress is padding. The about_you step is left out for the
# opposite reason: its own prompt says "None of this affects matching", so
# counting it would promise better matches for an answer that cannot give any.
class ProfileStrength
  # Slug to the fields whose presence means the step was genuinely answered,
  # rather than skipped. Skipping advances onboarding_step without writing
  # anything, so the step number cannot be used to tell them apart.
  SCORING_STEPS = {
    "logistics" => %i[willing_travel_miles remote_visit_preference],
    "preferences" => %i[trial_type_preference risk_tolerance]
  }.freeze

  attr_reader :profile

  def initialize(profile)
    @profile = profile
  end

  def total = SCORING_STEPS.length

  def answered = steps.count { |_slug, _step, done| done }

  def remaining = total - answered

  def complete? = remaining.zero?

  def percent = ((answered.to_f / total) * 100).round

  # [slug, Onboarding::Step, answered?] so the view can name what is missing and
  # link straight to the step that fills it.
  def steps
    @steps ||= SCORING_STEPS.map do |slug, fields|
      step = Onboarding.steps.find { |s| s.slug == slug }
      [slug, step, fields.any? { |field| profile.public_send(field).present? }]
    end
  end

  def unanswered = steps.reject { |_slug, _step, done| done }
end
