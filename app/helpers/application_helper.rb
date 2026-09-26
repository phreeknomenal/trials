module ApplicationHelper
  include Pagy::NumericHelperLoader

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
      "#{years} #{(years == 1) ? "year" : "years"}"
    elsif months >= 1
      "#{months} #{(months == 1) ? "month" : "months"}"
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
      {display: loc[:display], near_you: near_you}
    end.sort_by { |h| h[:near_you] ? 0 : 1 }
  end

  # Reads Shared::StatusBadgeComponent rather than restating it.
  #
  # This was a second copy of the same seven statuses, written before that
  # component existed and never given dark variants. SearchHelper carries a
  # third for the registry's own status words, and that one *was* updated, which
  # is how a saved-study badge came to sit at 4.24 against a 4.5 requirement in
  # dark mode while the identical badge on the results page passed.
  #
  # Two lists for one thing drift, and the drift is invisible: nothing fails,
  # one of them is just quietly wrong.
  def status_badge_classes(status)
    Shared::StatusBadgeComponent::STATUSES
      .fetch(status.to_s, {})
      .fetch(:classes, "bg-surface-2 text-ink-2 dark:bg-surface-2-on-dark dark:text-ink-2-on-dark")
  end

  # Both the registry and the model that rewrites it separate paragraphs with a
  # single newline, which simple_format renders as <br> inside one <p>. Four
  # paragraphs of prose then arrive as an unbroken wall with no gap anywhere in
  # it, which is most of why the study overview was hard to read.
  def prose_paragraphs(text)
    text.to_s.split(/\r?\n+/).map(&:strip).reject(&:blank?)
  end

  # The registry returns its enums shouted: "PHASE2", "INTERVENTIONAL",
  # "NOT_YET_RECRUITING", and phases arrive already joined as "PHASE1, PHASE2".
  # Nothing should print those at a patient.
  def humanize_registry_value(value)
    return "" if value.blank?

    value.to_s.split(",").map { |part|
      cleaned = part.strip

      # The registry uses NA for a study with no phase, which is most
      # observational ones. "Na" is not a phase.
      next "Not applicable" if cleaned.casecmp?("na")

      cleaned.tr("_", " ").downcase.gsub(/\bphase(\d)\b/, 'phase \\1').upcase_first
    }.join(", ")
  end
end
