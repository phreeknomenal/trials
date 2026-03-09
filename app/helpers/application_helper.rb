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

  def trial_duration(start_date, completion_date)
    return nil unless start_date.present? && completion_date.present?

    start_d = start_date.is_a?(String) ? Date.parse(start_date) : start_date
    end_d = completion_date.is_a?(String) ? Date.parse(completion_date) : completion_date
    return nil if end_d < start_d

    months = (end_d.year * 12 + end_d.month) - (start_d.year * 12 + start_d.month)
    if months >= 24
      years = (months / 12.0).round
      "#{years} #{years == 1 ? 'year' : 'years'}"
    elsif months >= 1
      "#{months} #{months == 1 ? 'month' : 'months'}"
    else
      "Less than 1 month"
    end
  rescue ArgumentError
    nil
  end

  def user_onboarded?
    user_signed_in? && current_user.profile&.onboarded?
  end

  # Sorts trial locations so those near the profile (same state/city) appear first.
  # Returns array of hashes with :display and :near_you.
  def sort_locations_near_user(locations_detailed, profile)
    return [] if locations_detailed.blank?

    profile_state = profile&.state&.to_s&.strip&.upcase
    profile_city = profile&.city&.to_s&.strip&.downcase

    locations_detailed.map do |loc|
      state = loc[:state]&.to_s&.strip&.upcase
      city = loc[:city]&.to_s&.strip&.downcase
      near_you = (profile_state.present? && state == profile_state) ||
                 (profile_city.present? && profile_state.present? && city == profile_city && state == profile_state)
      { display: loc[:display], near_you: near_you }
    end.sort_by { |h| h[:near_you] ? 0 : 1 }
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
