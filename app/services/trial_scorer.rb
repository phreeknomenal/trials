class TrialScorer
  # Scoring weights for different criteria (total = 100)
  WEIGHTS = {
    age: 20,
    sex: 20,
    conditions: 25,
    location: 15,
    study_type: 10,
    phase_risk: 10
  }.freeze

  def initialize(profile, trial_data)
    @profile = profile
    @trial = trial_data
  end

  def calculate_score
    return nil unless @profile && @trial

    scores = {
      age: score_age,
      sex: score_sex,
      conditions: score_conditions,
      location: score_location,
      study_type: score_study_type,
      phase_risk: score_phase_risk
    }

    # Calculate weighted total
    total = scores.sum { |criteria, score| score * WEIGHTS[criteria] / 100.0 }

    {
      total: total.round,
      breakdown: scores,
      match_level: match_level(total)
    }
  end

  private

  def score_age
    return 50 unless @profile.age # Neutral if age unknown

    min_age = parse_age(@trial[:min_age])
    max_age = parse_age(@trial[:max_age])

    # If no age restrictions, everyone matches
    return 100 if min_age.nil? && max_age.nil?

    profile_age = @profile.age

    # Check if within range
    within_min = min_age.nil? || profile_age >= min_age
    within_max = max_age.nil? || profile_age <= max_age

    return 100 if within_min && within_max
    0 # Outside age range
  end

  def score_sex
    trial_sex = @trial[:sex]&.downcase
    profile_sex = @profile.sex_assigned_at_birth&.downcase

    return 100 if trial_sex.nil? || trial_sex == "all"
    return 50 if profile_sex.nil? # Unknown sex, neutral score
    return 100 if trial_sex == profile_sex
    0
  end

  def score_conditions
    return 50 unless @profile.conditions.any? # Neutral if no conditions

    trial_conditions = Array(@trial[:conditions]).map(&:downcase)
    profile_conditions = @profile.conditions.map { |c| c.name.downcase }

    return 50 if trial_conditions.empty?

    # Calculate overlap percentage
    matching_conditions = profile_conditions.count do |pc|
      trial_conditions.any? { |tc| tc.include?(pc) || pc.include?(tc) }
    end

    # At least one condition must match to score above 0
    return 0 if matching_conditions.zero?

    (matching_conditions.to_f / profile_conditions.length * 100).round
  end

  def score_location
    return 50 unless @profile.city && @profile.state
    return 50 if @trial[:locations].empty?

    trial_locations = @trial[:locations]

    # Check if any location matches user's state or city
    state_match = trial_locations.any? { |loc| loc.to_s.include?(@profile.state) }
    city_match = trial_locations.any? { |loc| loc.to_s.include?(@profile.city) }

    return 100 if city_match
    return 75 if state_match
    25 # Different state but user might be willing to travel
  end

  def score_study_type
    return 100 if @profile.trial_type_preference == Profile::EITHER
    return 50 unless @profile.trial_type_preference

    trial_type = @trial[:study_type]&.downcase
    preference = @profile.trial_type_preference&.downcase

    return 100 if trial_type == preference
    50 # Doesn't match preference but not a dealbreaker
  end

  def score_phase_risk
    return 100 unless @profile.risk_tolerance
    return 100 unless @trial[:phase]

    phase = @trial[:phase]&.downcase

    case @profile.risk_tolerance
    when Profile::APPROVED_ONLY
      return 100 if phase.include?("phase 4") || phase.include?("not applicable")
      return 50 if phase.include?("phase 3")
      0
    when Profile::TESTED
      return 100 if phase.include?("phase 2") || phase.include?("phase 3") || phase.include?("phase 4")
      return 50 if phase.include?("phase 1")
      0
    when Profile::EARLY_STAGE_OKAY
      100 # Willing to try any phase
    else
      100
    end
  end

  def parse_age(age_string)
    return nil if age_string.nil?

    # Extract first number from strings like "18 Years", "65 Years", etc.
    age_string.to_s.scan(/\d+/).first&.to_i
  end

  def match_level(score)
    case score
    when 80..100 then "excellent"
    when 60..79 then "good"
    when 40..59 then "fair"
    else "poor"
    end
  end
end
