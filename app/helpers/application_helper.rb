module ApplicationHelper
  include Pagy::Loader

  def parse_date(date)
    return "N/A" unless date.presence

    date_obj = date.is_a?(String) ? Date.parse(date) : date
    date_obj.strftime("%B %d, %Y")
  rescue ArgumentError
    date.to_s
  end

  def parse_date_range(start_date, completion_date)
    parsed_start = start_date.presence ? parse_date(start_date) : nil
    parsed_end = completion_date.presence ? parse_date(completion_date) : nil

    if parsed_start && parsed_end
      "#{parsed_start} - #{parsed_end}"
    elsif parsed_start
      parsed_start
    elsif parsed_end
      parsed_end
    else
      "N/A"
    end
  end

  def user_onboarded?
    user_signed_in? && current_user.profile&.onboarded?
  end

  # Trial Score Display Helpers
  def match_score_bg_class(match_level)
    case match_level
    when "excellent"
      "bg-green-50 dark:bg-green-900/20"
    when "good"
      "bg-blue-50 dark:bg-blue-900/20"
    when "fair"
      "bg-yellow-50 dark:bg-yellow-900/20"
    else
      "bg-gray-50 dark:bg-gray-900/20"
    end
  end

  def match_score_border_class(match_level)
    case match_level
    when "excellent"
      "border-green-200 dark:border-green-800"
    when "good"
      "border-blue-200 dark:border-blue-800"
    when "fair"
      "border-yellow-200 dark:border-yellow-800"
    else
      "border-gray-200 dark:border-gray-800"
    end
  end

  def match_score_text_class(match_level)
    case match_level
    when "excellent"
      "text-green-800 dark:text-green-200"
    when "good"
      "text-blue-800 dark:text-blue-200"
    when "fair"
      "text-yellow-800 dark:text-yellow-200"
    else
      "text-gray-800 dark:text-gray-200"
    end
  end
end
