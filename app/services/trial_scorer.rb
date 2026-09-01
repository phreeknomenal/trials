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

  # Default configuration matching Profile model constants
  # This allows the scorer to work independently of the Profile class
  DEFAULT_CONFIG = {
    trial_type_preferences: {
      either: "either",
      interventional: "interventional",
      observational: "observational"
    },
    risk_tolerance_levels: {
      approved_only: "approved treatments only",
      tested: "tested in other patients",
      early_stage_okay: "early-stage is okay"
    }
  }.freeze

  AGE_UNITS_IN_YEARS = {
    "year" => 1.0,
    "month" => 1.0 / 12,
    "week" => 1.0 / 52.1775,
    "day" => 1.0 / 365.25
  }.freeze

  def initialize(profile, trial_data, config: DEFAULT_CONFIG)
    @profile = profile
    @trial = trial_data
    @config = config
  end

  INELIGIBLE = "ineligible".freeze

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

    total = scores.sum { |criteria, score| score * WEIGHTS[criteria] / 100.0 }
    failures = disqualifiers

    {
      eligible: failures.empty?,
      disqualifiers: failures,
      total: failures.empty? ? total.round : 0,
      breakdown: scores,
      match_level: failures.empty? ? match_level(total) : INELIGIBLE
    }
  end

  private

  # Age and sex are eligibility gates, not preferences. Folding them into the
  # weighted sum let a hard exclusion be outvoted: a 40-year-old scored 51 and
  # "fair" on a trial recruiting infants aged 0 to 28 days, because age scored 0
  # while sex, phase, and study type all returned neutral or full marks.
  #
  # A gate only fires on a definite mismatch. Unknown data is not a
  # disqualifier, so an incomplete profile stays eligible everywhere.
  def disqualifiers
    reasons = []
    reasons << :age if @profile.age.present? && score_age.zero?
    reasons << :sex if definite_sex_mismatch?
    reasons << :not_recruiting if TrialStatus.closed?(trial_status)
    reasons
  end

  def trial_status
    @trial[:status] || @trial[:trial_status]
  end

  def definite_sex_mismatch?
    @profile.sex_assigned_at_birth.present? && score_sex.zero?
  end

  public

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

    # Score = what percentage of MY conditions does this trial address?
    matching_conditions = profile_conditions.count do |pc|
      trial_conditions.any? { |tc| conditions_match?(pc, tc) }
    end

    # At least one condition must match to score above 0
    return 0 if matching_conditions.zero?

    # User-centric scoring: percentage of profile conditions that match
    # This doesn't penalize trials for studying additional conditions
    (matching_conditions.to_f / profile_conditions.length * 100).round
  end

  def score_location
    return 50 unless @profile.city && @profile.state

    trial_locations = @trial[:locations]
    return 50 if trial_locations.nil? || trial_locations.empty?

    state_match = trial_locations.any? { |loc| location_component?(loc, @profile.state) }
    city_match = trial_locations.any? { |loc| location_component?(loc, @profile.city) }

    return 100 if city_match
    return 75 if state_match
    25 # Different state but user might be willing to travel
  end

  def score_study_type
    return 100 if @profile.trial_type_preference == @config[:trial_type_preferences][:either]
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
    when @config[:risk_tolerance_levels][:approved_only]
      return 100 if phase.include?("phase 4") || phase.include?("not applicable")
      return 50 if phase.include?("phase 3")
      0
    when @config[:risk_tolerance_levels][:tested]
      return 100 if phase.include?("phase 2") || phase.include?("phase 3") || phase.include?("phase 4")
      return 50 if phase.include?("phase 1")
      0
    when @config[:risk_tolerance_levels][:early_stage_okay]
      100 # Willing to try any phase
    else
      100
    end
  end

  # Trial locations arrive as comma-separated components: "Kansas City,
  # Missouri, United States". A raw `include?` matched across those boundaries,
  # so a profile in Kansas matched a trial in Kansas City, MISSOURI, and one in
  # Virginia matched West Virginia. Comparing whole components instead means a
  # place name only matches the field it actually occupies.
  def location_component?(location, value)
    return false if value.blank?

    components = location.to_s.split(",").map { |part| part.strip.downcase }

    components.include?(value.to_s.strip.downcase)
  end

  # Compares conditions by whole words rather than raw substrings. A bare
  # `include?` matched any abbreviation appearing inside a longer word: "ms"
  # matched "symptoms" and "als" matched "false positives", both of which are
  # real conditions in the seeded list.
  #
  # One condition matches another when its words are a subset of the other's, so
  # a profile listing "lung cancer" still matches a trial studying "cancer", and
  # "breast cancer" still does not match "lung cancer".
  def conditions_match?(profile_condition, trial_condition)
    profile_words = condition_words(profile_condition)
    trial_words = condition_words(trial_condition)

    return false if profile_words.empty? || trial_words.empty?

    profile_words.subset?(trial_words) || trial_words.subset?(profile_words)
  end

  # Phrase-level equivalences applied before tokenising, for cases a per-word map
  # cannot reach: "human immunodeficiency virus" has to collapse to one token to
  # match a profile holding "HIV/AIDS".
  CONDITION_PHRASES = {
    /human immunodeficiency virus/ => "hiv",
    /acquired immunodeficiency syndrome/ => "aids"
  }.freeze

  # Word-level equivalences. The cancer group matters most: the registry uses
  # carcinoma, neoplasm, and tumour interchangeably with cancer, and oncology is
  # a large share of it. Roman numerals cover "Type II" against "type 2"; bare
  # "i" is deliberately excluded as too ambiguous to fold.
  CONDITION_SYNONYMS = {
    "carcinoma" => "cancer",
    "neoplasm" => "cancer",
    "neoplasms" => "cancer",
    "tumor" => "cancer",
    "tumour" => "cancer",
    "ii" => "2",
    "iii" => "3",
    "iv" => "4"
  }.freeze

  def condition_words(text)
    normalised = text.to_s.downcase
    CONDITION_PHRASES.each { |pattern, replacement| normalised = normalised.gsub(pattern, replacement) }

    # "Type2" arrives as one token in real payloads, so split letter/digit runs.
    normalised = normalised.gsub(/([a-z])(\d)/, '\1 \2').gsub(/(\d)([a-z])/, '\1 \2')

    normalised.scan(/[a-z0-9]+/)
      .map { |word| CONDITION_SYNONYMS.fetch(word, word) }
      .to_set
  end

  # ClinicalTrials.gov expresses age limits with a unit: "18 Years", "6 Months",
  # "30 Days". Reading the number alone treated all three as years, so a trial
  # open from 6 months of age was scored as requiring a minimum of 6 years.
  # Everything normalises to years so one comparison works for all of them.
  def parse_age(age_string)
    return nil if age_string.nil?

    text = age_string.to_s.downcase
    number = text[/\d+(?:\.\d+)?/]
    return nil if number.nil?

    unit = AGE_UNITS_IN_YEARS.keys.find { |name| text.include?(name) }

    number.to_f * AGE_UNITS_IN_YEARS.fetch(unit, 1.0)
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
