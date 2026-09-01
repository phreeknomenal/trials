# The wizard's step vocabulary, in one place.
#
# Steps are ordered by what trial matching actually needs. The first four are
# required because a profile without them cannot be scored against anything:
# age and sex are eligibility gates, conditions carry the largest single weight
# at 25, and location is worth 15 and had no way in before zip resolution.
#
# Each step saves under its own validation context. Profile's presence
# validations are declared `on: :update` because User#add_default_profile
# persists a blank profile at signup, so create has to stay unvalidated. That
# means a partial save carrying only one step's fields would fail on every
# field the user has not reached yet. A per-step context runs that step's rules
# and skips the rest.
module Onboarding
  Step = Data.define(:slug, :heading, :prompt, :required, :permitted) do
    def context
      :"onboarding_#{slug}"
    end

    def component
      "Onboarding::Steps::#{slug.camelize}Component".constantize
    end

    def required?
      required
    end

    def number
      Onboarding.number_for(self)
    end
  end

  STEPS = [
    Step.new(
      slug: "identity",
      heading: "First, what should we call you?",
      prompt: "This is only used to personalise the app. It is never sent to a study team.",
      required: true,
      permitted: [:first_name, :last_name]
    ),
    Step.new(
      slug: "basics",
      heading: "A little about you",
      prompt: "Studies set age and sex eligibility rules. These two let us rule out the ones you could not join.",
      required: true,
      permitted: [:birth_year, :sex_assigned_at_birth]
    ),
    Step.new(
      slug: "location",
      heading: "Where are you?",
      prompt: "Your zip code tells us which study sites are near you. We never store a street address.",
      required: true,
      permitted: [:zip_code]
    ),
    Step.new(
      slug: "conditions",
      heading: "What are you looking for a study about?",
      prompt: "This matters more than anything else here. It is the largest single factor in how studies are ranked for you.",
      required: true,
      permitted: [:no_conditions, {profile_conditions_attributes: [:id, :condition_id, :is_primary, :_destroy]}]
    )
  ].freeze

  module_function

  def steps
    STEPS
  end

  def count
    STEPS.length
  end

  def required_count
    STEPS.count(&:required?)
  end

  def find(slug)
    STEPS.find { |step| step.slug == slug.to_s }
  end

  # 1-based, matching Profile#onboarding_step.
  def at(number)
    return nil if number.to_i < 1

    STEPS[number.to_i - 1]
  end

  def number_for(step)
    STEPS.index(step) + 1
  end

  def first
    STEPS.first
  end

  # The value Profile#onboarding_step holds once every step is behind you.
  def complete_number
    count + 1
  end

  # The value at which the app unlocks. Optional steps come after it.
  def unlocked_number
    required_count + 1
  end
end
