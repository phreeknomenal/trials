class Page::Trials::StatusMessageComponent < ApplicationComponent
  attr_reader :study, :score_breakdown, :trial_score, :match_level

  def initialize(study:, score_breakdown: nil, trial_score: nil, match_level: nil)
    @study = study
    @score_breakdown = score_breakdown
    @trial_score = trial_score
    @match_level = match_level
  end

  def status_message
    case status
    when "completed"
      "This study is completed, which means you cannot enroll, but it may still help you understand your risk and find similar active studies."
    when "recruiting"
      "This study is currently enrolling new participants. Based on your profile, you may be a good fit."
    when "not_yet_recruiting"
      "This study is not yet enrolling participants, but you can still review the details to see if it might be relevant for you."
    when "active_not_recruiting"
      "This study is active but not currently enrolling new participants."
    else
      nil
    end
  end


  def aria_label
    case status
    when "completed"
      "Study status: Completed and closed to enrollment"
    when "recruiting"
      "Study status: Currently recruiting and accepting new participants"
    when "not_yet_recruiting"
      "Study status: Not yet recruiting, coming soon"
    when "active_not_recruiting"
      "Study status: Active study but not currently recruiting"
    else
      "Study status information"
    end
  end

  def match_factors
    return [] unless score_breakdown.present?

    factors = []

    # Map score_breakdown keys to user-friendly labels
    factor_labels = {
      age: "Age",
      sex: "Sex/Gender",
      conditions: "Medical Condition",
      location: "Location",
      study_type: "Study Type",
      phase_risk: "Risk Level"
    }

    score_breakdown.each do |key, value|
      # Value is a direct score (integer), not a hash
      score = value.to_i
      label = factor_labels[key.to_sym] || key.to_s.humanize
      message = message_for_factor(key.to_sym, score)

      factors << {
        label: label,
        score: score,
        message: message,
        key: key,
        css_classes: css_classes_for_score(score)
      }
    end

    # Sort by score descending (best matches first)
    factors.sort_by { |f| -f[:score] }
  end

  def css_classes_for_score(score)
    base_classes = "flex items-start gap-3 pl-3 py-2 rounded border-l-4 border "

    if score >= 75
      base_classes + "border-green-600 dark:border-green-500 bg-green-50 dark:bg-green-900/10"
    elsif score >= 50
      base_classes + "border-amber-600 dark:border-amber-500 bg-amber-50 dark:bg-amber-900/10"
    else
      base_classes + "border-red-600 dark:border-red-500 bg-red-50 dark:bg-red-900/10"
    end
  end

  def message_for_factor(factor_key, score)
    case factor_key
    when :age
      case score
      when 100
        "Your age is within the study's requirements"
      when 50
        "Your age information is incomplete, but may be acceptable"
      else
        "You don't meet the age requirements for this study"
      end
    when :sex
      case score
      when 100
        "Your sex/gender matches the study criteria"
      when 50
        "Your sex/gender information wasn't provided, but may be acceptable"
      else
        "The study has specific sex/gender requirements you don't meet"
      end
    when :conditions
      case score
      when 100
        "All of your conditions align with this study's focus"
      when 50
        "Some of your conditions match the study's focus"
      else
        "Your medical conditions don't match the study's requirements"
      end
    when :location
      case score
      when 100
        "There's a study site in your city"
      when 75
        "There's a study site in your state"
      when 25
        "Study locations are in different states but you may be able to travel"
      else
        "No nearby study locations match your area"
      end
    when :study_type
      case score
      when 100
        "This study type matches your preferences"
      when 50
        "This study type is neutral to your preferences"
      else
        "This study type doesn't match your preferences"
      end
    when :phase_risk
      case score
      when 100
        "The study phase aligns with your risk tolerance"
      when 50
        "The study phase is somewhat aligned with your risk tolerance"
      else
        "The study phase doesn't align with your risk tolerance"
      end
    else
      "Match information available"
    end
  end

  private

  def status
    @study[:status]&.downcase
  end

  def completion_date_text
    if @study[:completion_date].present?
      "Ended on #{format_date(@study[:completion_date])}"
    else
      "This study has been completed"
    end
  end

  def available_spots_text
    if @study[:enrollment_count].present?
      "Approximately #{@study[:enrollment_count]} participants enrolled"
    else
      "Actively enrolling participants"
    end
  end

  def start_date_text
    if @study[:start_date].present?
      "Expected to start: #{format_date(@study[:start_date])}"
    else
      "Start date to be announced"
    end
  end

  def format_date(date_string)
    return nil unless date_string.present?

    begin
      Date.parse(date_string).strftime("%B %d, %Y")
    rescue
      date_string
    end
  end
end
