# Where the study takes place.
#
# Two things decide the shape of this, both measured from the registry on
# 2026-09-27 across 800 recruiting studies:
#
#   - The median study has ONE site. Two thirds have exactly one and 77% have
#     three or fewer, so for most studies this is a single row and no summary.
#   - The tail is brutal. p90 is 18 sites and the largest seen was 413, so the
#     section cannot simply render them all inline.
#
# It never filters. 58% of recruiting studies have no US sites at all, so
# showing only what is "relevant" would empty the section for most of them, and
# "the nearest site is in Osaka" is the answer somebody needs rather than a
# blank panel. The long ones are capped and counted instead.
class Page::Trials::LocationsComponent < ApplicationComponent
  VISIBLE = 6

  attr_reader :study, :profile

  def initialize(study:, profile: nil)
    @study = study
    @profile = profile
  end

  def render? = locations.any?

  # Near-first, then the registry's own order. "Near" is a match on the
  # profile's state, which is all the data supports today. The coordinates the
  # client now captures make a real distance possible; that is
  # Tasks/trials-location-distance.md, not this.
  def locations
    @locations ||= rows.each_with_index
      .sort_by { |loc, index| [near?(loc) ? 0 : 1, index] }
      .map(&:first)
  end

  def visible = locations.first(VISIBLE)

  def hidden = locations.drop(VISIBLE)

  def hidden? = hidden.any?

  # Industry studies name every site the same thing: 67 rows reading "GSK
  # Investigational Site" put an identical bold line above each city, so the
  # one distinguishing fact sits in the smaller grey line underneath. Where a
  # facility name does not tell two sites apart, the place leads instead.
  def repeated_facility?(location)
    name = location[:facility].to_s.strip.downcase
    return false if name.blank?

    repeated_facilities.include?(name)
  end

  def near?(location)
    return false if profile_state.blank?

    location[:state].to_s.strip.casecmp?(profile_state)
  end

  # Only earns its place when there is more than one site. With a single row
  # the row already says everything the summary would.
  def summary
    return nil if locations.length < 2

    [spread_phrase, state_phrase].compact.join(" ")
  end

  private

  def rows
    detailed = Array(study[:locations_detailed])
    return detailed.select { |l| l[:facility].present? || l[:display].present? } if detailed.any?

    Array(study[:locations]).compact_blank.map { |l| {display: l} }
  end

  def repeated_facilities
    @repeated_facilities ||= locations
      .filter_map { |l| l[:facility].to_s.strip.downcase.presence }
      .tally
      .select { |_name, count| count > 1 }
      .keys
      .to_set
  end

  def profile_state = profile&.state.to_s.strip.presence

  def spread_phrase
    countries = locations.filter_map { |l| l[:country].presence }.uniq
    sites = helpers.pluralize(locations.length, "site")

    return "#{sites}." if countries.empty?
    return "#{sites} in #{countries.first}." if countries.one?

    "#{sites} across #{countries.length} countries."
  end

  # The sentence somebody actually came for. Said even when the answer is none,
  # because none is the answer.
  def state_phrase
    return nil if profile_state.blank?

    count = locations.count { |l| near?(l) }
    count.zero? ? "None in #{profile_state}." : "#{count} in #{profile_state}."
  end
end
