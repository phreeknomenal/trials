# Great-circle distance in miles.
#
# Haversine rather than anything cleverer: the error against the real geoid is
# well under half a percent, and every question this answers is of the form "is
# this site within the sixty miles you said you could travel".
module Distance
  EARTH_RADIUS_MILES = 3958.7613

  module_function

  # Nil when either end is unknown, which is the normal case rather than an
  # error: a profile may have no postal code, and 2% of registry locations carry
  # no coordinates.
  def between(from, to)
    from_lat, from_lon = coordinates(from)
    to_lat, to_lon = coordinates(to)
    return nil if from_lat.nil? || to_lat.nil?

    d_lat = radians(to_lat - from_lat)
    d_lon = radians(to_lon - from_lon)

    a = (Math.sin(d_lat / 2)**2) +
      (Math.cos(radians(from_lat)) * Math.cos(radians(to_lat)) * (Math.sin(d_lon / 2)**2))

    (2 * EARTH_RADIUS_MILES * Math.asin(Math.sqrt(a))).round(1)
  end

  # Accepts [lat, lon], {lat:, lon:} and anything answering to #coordinates, so
  # callers do not each unpack the registry's shape themselves.
  def coordinates(point)
    return [nil, nil] if point.blank?
    return point.coordinates if point.respond_to?(:coordinates)
    return [point[0], point[1]] if point.is_a?(Array)

    [point[:lat] || point["lat"], point[:lon] || point["lon"]]
  rescue
    [nil, nil]
  end

  def radians(degrees) = degrees.to_f * Math::PI / 180
end
