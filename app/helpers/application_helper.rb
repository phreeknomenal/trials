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

  def status_badge_classes(status)
    case status
    when "interested"
      "bg-blue-100 text-blue-800"
    when "applying"
      "bg-yellow-100 text-yellow-800"
    when "contacted"
      "bg-purple-100 text-purple-800"
    when "enrolled"
      "bg-green-100 text-green-800"
    when "rejected"
      "bg-red-100 text-red-800"
    when "completed"
      "bg-gray-100 text-gray-800"
    when "not_eligible"
      "bg-orange-100 text-orange-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
end
