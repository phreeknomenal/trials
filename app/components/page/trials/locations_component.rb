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

  # Nearest first. Unknown sorts last rather than first, because a site with no
  # coordinates is not a site that is nearby.
  #
  # The state match stays as the second key rather than being replaced by the
  # distance: when nothing can be measured — no postal code on the profile, or
  # no coordinates on the sites — it is the only ordering there is, and dropping
  # it left the reader's own state wherever the registry happened to put it.
  def locations
    @locations ||= rows.each_with_index
      .sort_by { |loc, index| [distance_for(loc) || Float::INFINITY, state_match?(loc) ? 0 : 1, index] }
      .map(&:first)
  end

  # Nil when either end has no point, which is the normal case rather than an
  # error: a profile may carry no postal code, and 2% of registry locations
  # publish no coordinates.
  def distance_for(location)
    return nil if origin.nil?

    @distances ||= {}
    @distances.fetch(location.object_id) do
      @distances[location.object_id] = Distance.between(origin, location[:geo_point])
    end
  end

  def origin = @origin ||= profile&.coordinates

  # The one number this app has collected since onboarding and never read.
  def travel_limit = profile&.willing_travel_miles

  def within_limit?(location)
    return false if travel_limit.blank?

    miles = distance_for(location)
    miles.present? && miles <= travel_limit
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

  # Falls back to the state match when there is no distance to be had, so a
  # profile with no postal code still gets its own state marked.
  def near?(location)
    return within_limit?(location) if origin.present? && travel_limit.present?

    state_match?(location)
  end

  def state_match?(location)
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
  #
  # In miles where the profile has a postal code and a travel limit, which is
  # the question they were asked at onboarding and the one nothing has read
  # since. By state otherwise.
  def state_phrase
    return travel_phrase if origin.present? && travel_limit.present?
    return nil if profile_state.blank?

    count = locations.count { |l| state_match?(l) }
    count.zero? ? "None in #{profile_state}." : "#{count} in #{profile_state}."
  end

  def travel_phrase
    count = locations.count { |l| within_limit?(l) }
    return "None within the #{travel_limit} miles you said you could travel." if count.zero?

    "#{count} within the #{travel_limit} miles you said you could travel."
  end
end
