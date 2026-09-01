class Page::Trials::KeyDetails::MatchScoreCardComponent < ApplicationComponent
  def initialize(trial_score:, match_level:, score_breakdown:, profile: nil, trial: nil)
    @trial_score = trial_score
    @match_level = match_level
    @score_breakdown = score_breakdown
    @profile = profile
    @trial = trial
  end

  def match_phrase(match_level)
    case match_level
    when "excellent"
      "You're an excellent match for this study."
    when "good"
      "You're a good match for this study."
    when "fair"
      "You're a fair match for this study."
    else
      "You're a poor match for this study."
    end
  end

  def breakdown_items
    [
      {label: "Age", value: @score_breakdown[:age], icon: "calendar_month"},
      {label: "Sex", value: @score_breakdown[:sex], icon: "user"},
      {label: "Conditions", value: @score_breakdown[:conditions], icon: "microscope"},
      {label: "Location", value: @score_breakdown[:location], icon: "map_pin"},
      {label: "Study Type", value: @score_breakdown[:study_type], icon: "rectangle_stack"},
      {label: "Risk Level", value: @score_breakdown[:phase_risk], icon: "exclamation_triangle"}
    ]
  end

  def generate_explanations
    return {} unless @profile && @trial

    {
      age: generate_age_explanation,
      sex: generate_sex_explanation,
      conditions: generate_conditions_explanation,
      location: generate_location_explanation,
      study_type: generate_study_type_explanation,
      phase_risk: generate_phase_risk_explanation
    }
  end

  private

  def generate_age_explanation
    return "Age information not available." unless @profile.age && @trial

    user_age = @profile.age
    min_age = parse_age(@trial[:min_age])
    max_age = parse_age(@trial[:max_age])

    if min_age.nil? && max_age.nil?
      "You're #{user_age} years old. This trial has no age restrictions."
    elsif min_age && max_age
      in_range = user_age.between?(min_age, max_age)
      status = in_range ? "✓ You're within the accepted age range." : "✗ You're outside the accepted age range."
      "You're #{user_age} years old. #{status} This trial accepts ages #{min_age}-#{max_age}."
    elsif min_age
      in_range = user_age >= min_age
      status = in_range ? "✓ You meet the minimum age requirement." : "✗ You don't meet the minimum age requirement."
      "You're #{user_age} years old. #{status} Minimum age: #{min_age}."
    else
      in_range = user_age <= max_age
      status = in_range ? "✓ You're within the age limit." : "✗ You exceed the age limit."
      "You're #{user_age} years old. #{status} Maximum age: #{max_age}."
    end
  end

  def generate_sex_explanation
    return "Sex information not available." unless @profile.sex_assigned_at_birth && @trial

    user_sex = @profile.sex_assigned_at_birth.capitalize
    trial_sex = @trial[:sex]

    return "Your profile shows #{user_sex}. Trial accepts all sexes." if trial_sex.nil? || trial_sex.downcase == "all"

    if trial_sex.downcase == @profile.sex_assigned_at_birth.downcase
      "✓ Your sex matches. Your profile shows #{user_sex}. Trial accepts #{trial_sex}."
    else
      "✗ Sex mismatch. Your profile shows #{user_sex}, but trial only accepts #{trial_sex}."
    end
  end

  def generate_conditions_explanation
    return "Condition information not available." unless @profile.conditions.any?

    trial_conditions = Array(@trial[:conditions]).map(&:downcase)
    profile_conditions = @profile.conditions.map(&:name)

    return "Trial has no specific condition restrictions." if trial_conditions.empty?

    matching = profile_conditions.filter do |pc|
      trial_conditions.any? { |tc| tc.include?(pc.downcase) || pc.downcase.include?(tc) }
    end

    if matching.any?
      non_matching = profile_conditions - matching
      msg = "✓ This trial addresses #{matching.join(", ")}."
      msg += " Conditions not covered: #{non_matching.join(", ")}." if non_matching.any?
      msg
    else
      "✗ None of your conditions match this trial's focus areas."
    end
  end

  def generate_location_explanation
    return "Location information not available." unless @profile.city && @profile.state

    user_location = "#{@profile.city}, #{@profile.state}"
    trial_locations = @trial[:locations] || []

    return "Trial location information not available." if trial_locations.empty?

    city_match = trial_locations.any? { |loc| loc.to_s.include?(@profile.city) }
    state_match = trial_locations.any? { |loc| loc.to_s.include?(@profile.state) }

    if city_match
      "✓ Exact city match. You're in #{user_location}. Trial is located in #{trial_locations.join(", ")}."
    elsif state_match
      "Trial is in your state (#{@profile.state}) but not your city (#{@profile.city}). Locations: #{trial_locations.join(", ")}."
    else
      "✗ Trial is in a different state. You're in #{user_location}. Trial locations: #{trial_locations.join(", ")}."
    end
  end

  def generate_study_type_explanation
    return "Study type information not available." unless @profile.trial_type_preference && @trial[:study_type]

    preference = @profile.trial_type_preference
    trial_type = @trial[:study_type]

    if preference.downcase == "either"
      "Your profile accepts both study types. This trial is #{trial_type}."
    elsif preference.downcase == trial_type.downcase
      "✓ This trial matches your preference for #{preference} studies."
    else
      "This trial is #{trial_type}, but you prefer #{preference}. Not a dealbreaker though!"
    end
  end

  # Explains the phase_risk number to the user, so it has to agree with
  # TrialScorer#score_phase_risk. Both used to carry their own idea of the
  # registry's format and both were wrong: this one tested include?("Phase 4")
  # against "PHASE4", so a risk-averse user reading a genuine Phase 4 trial was
  # told it did not match their preference. TrialPhase is the shared vocabulary.
  #
  # It also interpolated the raw value, rendering "This Phase PHASE4 trial".
  # TrialPhase.label produces the display form.
  def generate_phase_risk_explanation
    return "Risk information not available." unless @profile.risk_tolerance
    return "Risk information not available." if TrialPhase.blank?(@trial[:phase])

    phase = @trial[:phase]
    label = TrialPhase.label(phase)
    tolerance = @profile.risk_tolerance

    # A study with no FDA phase administers no investigational drug, so there is
    # no phase risk to weigh against any tolerance.
    return "✓ This study has no trial phase, so there is no phase risk to weigh." if TrialPhase.not_applicable?(phase)

    case tolerance
    when Profile::APPROVED_ONLY
      if TrialPhase.at_least?(phase, TrialPhase::PHASE4)
        "✓ This #{label} trial fits your preference for approved treatments."
      elsif TrialPhase.at_least?(phase, TrialPhase::PHASE3)
        "This #{label} trial is somewhat tested, but you prefer Phase 4 or approved treatments."
      else
        "✗ This #{label} trial doesn't match your preference for approved treatments only."
      end
    when Profile::TESTED
      if TrialPhase.at_least?(phase, TrialPhase::PHASE2)
        "✓ This #{label} trial has been tested. Matches your risk tolerance."
      elsif TrialPhase.at_least?(phase, TrialPhase::PHASE1)
        "This #{label} trial has minimal testing. You prefer Phase 2+ trials."
      else
        "✗ This #{label} trial is the earliest stage of human testing. You prefer Phase 2+ trials."
      end
    when Profile::EARLY_STAGE_OKAY
      "✓ You're open to any phase. This trial is #{label}."
    else
      "Your risk tolerance: #{tolerance}. This trial is #{label}."
    end
  end

  def parse_age(age_string)
    return nil if age_string.nil?
    age_string.to_s.scan(/\d+/).first&.to_i
  end
end
