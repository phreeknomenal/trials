# frozen_string_literal: true

class Page::Trials::KeyDatesTimelineComponent < ApplicationComponent
  def initialize(study:)
    @study = study
  end

  def start_date
    @study[:start_date]
  end

  def primary_completion_date
    @study[:primary_completion_date]
  end

  def completion_date
    @study[:completion_date]
  end

  def dates
    [
      ["Study start", start_date],
      ["Primary completion", primary_completion_date],
      ["Study completion", completion_date]
    ].reject { |_label, d| d.blank? }.uniq { |_label, d| d }
  end

  def render?
    dates.any?
  end

  def format_date(date_value)
    return date_value if date_value.blank?

    if date_value.is_a?(Date)
      date_value.strftime("%b %d, %Y")
    else
      Date.parse(date_value.to_s).strftime("%b %d, %Y")
    end
  rescue ArgumentError
    date_value.to_s
  end
end
