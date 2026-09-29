# One site. Its own component so the capped list and the disclosure below it
# render the same row rather than two copies of the same markup.
class Page::Trials::LocationRowComponent < ApplicationComponent
  attr_reader :location, :near, :lead_with_place, :miles

  # lead_with_place when the facility's name is shared with another site in the
  # same study, which industry sponsors do for every site they run. The parent
  # decides that, and the distance, because both need all the sites to know.
  def initialize(location:, near: false, lead_with_place: false, miles: nil)
    @location = location
    @near = near
    @lead_with_place = lead_with_place
    @miles = miles
  end

  # Rounded to the mile. The registry gives a town centroid and the profile a
  # postal code centroid, so a tenth of a mile would be precision neither end
  # of the calculation has.
  def distance_phrase
    return nil if miles.blank?

    "#{miles.round} miles away"
  end

  # The facility's own name where the registry gives one, which it does on
  # every location. The page used to lead with "Birmingham, Alabama" because
  # the client dropped this field.
  def title
    return place if lead_with_place || facility.blank?

    facility
  end

  def meta
    parts = [distance_phrase]
    parts << (lead_with_place ? facility : place) if facility.present?
    parts << status_phrase
    parts.compact_blank.join(" \u00b7 ")
  end

  def facility = location[:facility].presence

  def place = location[:display].presence

  # The site's own recruitment state, which is not the study's: a study of
  # twenty sites can be recruiting while this one has closed. Read through
  # TrialStatus so this does not become a second list of registry statuses.
  def status_phrase
    value = location[:status]
    return nil if value.blank?

    TrialStatus.open?(value) ? "Enrolling now" : TrialStatus.label(value)
  end

  # A maps query on the site's own address. With no distance in the data the
  # app cannot say how far away it is, only how to get there.
  def directions_url
    query = [location[:facility], location[:display]].compact_blank.join(", ")

    "https://www.google.com/maps/search/?api=1&query=#{CGI.escape(query)}"
  end
end
