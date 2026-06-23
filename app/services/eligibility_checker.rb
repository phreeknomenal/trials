class EligibilityChecker
  def initialize(profile, trial_data)
    @profile = profile
    @trial = trial_data
  end

  def build_checklist
    return [] unless @profile && @trial

    [
      check_age,
      check_sex,
      check_status,
      check_conditions,
      check_parsed_criteria
    ].compact
  end

  private

  def check_age
    min_age = parse_age(@trial[:min_age])
    max_age = parse_age(@trial[:max_age])

    if min_age.nil? && max_age.nil?
      return nil
    end

    user_age = @profile.age
    return build_item("Age", "unknown", "Your age is not available in your profile") unless user_age

    within_min = min_age.nil? || user_age >= min_age
    within_max = max_age.nil? || user_age <= max_age
    meets = within_min && within_max

    age_range_text = if min_age && max_age
      "#{min_age} - #{max_age} years"
    elsif min_age
      "#{min_age}+ years"
    elsif max_age
      "Up to #{max_age} years"
    end

    explanation = if meets
      "You are #{user_age} years old. This trial accepts ages #{age_range_text}."
    else
      "You are #{user_age} years old, but this trial requires ages #{age_range_text}. You may not be eligible."
    end

    build_item("Age", meets ? "met" : "not_met", explanation)
  end

  def check_sex
    trial_sex = @trial[:sex]&.downcase
    profile_sex = @profile.sex_assigned_at_birth&.downcase

    case trial_sex
    when nil, "all"
      return nil
    when profile_sex
      status = "met"
      explanation = "This trial accepts #{trial_sex}. Your profile matches."
    else
      status = profile_sex ? "not_met" : "unknown"
      explanation = if profile_sex
        "This trial requires #{trial_sex}, but your profile indicates #{profile_sex}."
      else
        "Your sex/gender is not specified in your profile."
      end
    end

    build_item("Sex/Gender", status, explanation)
  end

  def check_status
    trial_status = @trial[:status]&.downcase || @trial[:trial_status]&.downcase

    recruiting_statuses = ["recruiting", "active, not recruiting", "enrolling by invitation"]
    is_recruiting = recruiting_statuses.any? { |status| trial_status&.include?(status) }

    return nil unless trial_status

    status = is_recruiting ? "met" : "warning"
    explanation = if is_recruiting
      "This trial is actively recruiting participants."
    else
      "This trial status is: #{@trial[:status] || @trial[:trial_status]}. You may want to verify current enrollment before reaching out."
    end

    build_item("Recruitment Status", status, explanation)
  end

  def check_conditions
    user_conditions = @profile.conditions.map { |c| c.name.downcase }
    trial_conditions = Array(@trial[:conditions]).map(&:downcase)

    return nil if user_conditions.empty? || trial_conditions.empty?

    matching = user_conditions.count do |uc|
      trial_conditions.any? { |tc| tc.include?(uc) || uc.include?(tc) }
    end

    meets = matching > 0
    total = user_conditions.length

    status = if meets
      (matching == total) ? "met" : "warning"
    else
      "not_met"
    end

    if matching > 0
      explanation = "#{matching}/#{total} of your conditions match this trial. "
      explanation += (matching == total) ? "Excellent!" : "Partial match."
    else
      explanation = "None of your recorded conditions directly match this trial's focus areas."
    end

    build_item("Health Conditions", status, explanation)
  end

  def check_parsed_criteria
    criteria_text = @trial[:inclusion_criteria] || ""
    return nil if criteria_text.blank?

    parsed_items = parse_criteria_summary(criteria_text)
    return nil if parsed_items.empty?

    summary = parsed_items.join(" | ")
    build_item(
      "Eligibility Criteria Highlights",
      "info",
      summary,
      is_expandable: true,
      full_text: criteria_text
    )
  end

  def parse_criteria_summary(criteria_text)
    criteria_text = criteria_text.downcase

    extracted = []

    if criteria_text.include?("diagnosed") || criteria_text.include?("diagnosis")
      extracted << "Confirmed diagnosis required"
    end

    if criteria_text.include?("pregnant") || criteria_text.include?("pregnancy")
      extracted << "Pregnancy status may apply"
    end

    if criteria_text.include?("prior treatment") || criteria_text.include?("no previous")
      extracted << "Prior treatment restrictions may apply"
    end

    if criteria_text.include?("liver") || criteria_text.include?("renal") || criteria_text.include?("kidney")
      extracted << "Organ function requirements may apply"
    end

    if criteria_text.include?("performance status") || criteria_text.include?("ecog")
      extracted << "Physical performance requirements apply"
    end

    if criteria_text.include?("enrollment closed") || criteria_text.include?("not accepting")
      extracted << "Currently not accepting new participants"
    end

    extracted.take(4)
  end

  def parse_age(age_string)
    return nil if age_string.nil?

    age_string.to_s.scan(/\d+/).first&.to_i
  end

  def build_item(label, status, explanation, is_expandable: false, full_text: nil)
    {
      label: label,
      status: status,
      explanation: explanation,
      is_expandable: is_expandable,
      full_text: full_text,
      icon: get_icon_for_status(status)
    }
  end

  def get_icon_for_status(status)
    case status
    when "met"
      "badge_check"
    when "not_met"
      "exclamation_triangle"
    when "warning"
      "exclamation_triangle"
    when "unknown"
      "bookmark"
    else
      "bookmark"
    end
  end
end
