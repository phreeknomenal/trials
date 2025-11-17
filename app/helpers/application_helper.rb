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
end
