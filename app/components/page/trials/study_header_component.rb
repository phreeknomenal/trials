# The study's own header panel, from the board.
#
# It replaces a full-width banner that sat above the breadcrumb. The board puts
# this inside the main column as the first panel, which is why it looked like a
# different page: a banner spanning the viewport above a two-column layout reads
# as page chrome, and this is the study.
#
# The eyebrow carries phase, recruitment status and when the record was last
# touched. The last of those matters more than it looks: a registry entry is
# only as current as its last edit, and a patient reading it has no other way to
# know whether "recruiting" was true last week or last year.
class Page::Trials::StudyHeaderComponent < ApplicationComponent
  attr_reader :study, :nct_id, :saved_trial, :match_score

  def initialize(study:, nct_id:, saved_trial: nil, match_score: nil)
    @study = study
    @nct_id = nct_id
    @saved_trial = saved_trial
    @match_score = match_score
  end

  def eyebrow_parts
    [
      helpers.humanize_registry_value(study[:phase]).presence,
      helpers.humanize_registry_value(study[:status]).presence,
      last_updated_phrase
    ].compact
  end

  def last_updated_phrase
    date = parse_date(study[:last_update])
    return nil if date.nil?

    "Record updated #{date.to_fs(:long)}"
  end

  # The board's facts are a distance, a visit cadence and whether travel is
  # reimbursed. The registry returns none of the three, which this project has
  # recorded three times now. These are the facts it does return, and they
  # answer the same shape of question: is this for someone like me, and how big
  # a study is it.
  def facts
    [
      ["rectangle_stack", helpers.humanize_registry_value(study[:study_type]).presence],
      ["user", age_phrase],
      ["users_group", enrollment_phrase],
      ["map_pin", location_phrase]
    ].select { |_, value| value.present? }
  end

  # The registry gives these as "18 Years", unit included, so the unit is
  # stripped and said once. Left alone it reads "Ages 18 Years to 70 Years".
  def age_phrase
    low, high = age_number(study[:min_age]), age_number(study[:max_age])
    return nil if low.blank? && high.blank?
    return "Ages #{low} and over" if high.blank?
    return "Up to age #{high}" if low.blank?

    "Ages #{low} to #{high}"
  end

  def age_number(value)
    value.to_s[/\d+/]
  end

  def enrollment_phrase
    count = study[:enrollment_count]
    return nil if count.blank?

    "#{helpers.number_with_delimiter(count)} taking part"
  end

  # A count, not a distance. There is no distance anywhere in the data.
  def location_phrase
    count = Array(study[:locations_detailed]).length
    return nil if count.zero?

    helpers.pluralize(count, "site")
  end

  def savable?
    user_signed_in? && nct_id.present? && study[:title].present?
  end

  private

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue Date::Error
    nil
  end
end
