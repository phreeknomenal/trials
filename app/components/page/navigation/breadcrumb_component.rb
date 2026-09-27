class Page::Navigation::BreadcrumbComponent < ApplicationComponent
  # `current` names the last crumb when the URL segment is not a name a reader
  # recognises. On a study that segment is the registry id, so the trail read
  # "Home / Search / Nct06427018": three crumbs, and the one telling you where
  # you are was an accession number with a capital N.
  def initialize(current: nil)
    @current = current
  end

  def crumbs
    endpoints.map.with_index do |endpoint, index|
      path = endpoint_path(endpoints, index)

      next if path.blank?
      {
        name: endpoint_name(endpoint, path),
        path: path
      }
    end.compact
  end

  def endpoints
    @endpoints ||= request.path.split("/").reject!(&:empty?) || []
  end

  def endpoint_path(endpoints, index)
    path = "/#{endpoints[0..index].join("/")}"

    path if path_exists?(path) # && !path.eql?(request.path)
  end

  def endpoint_name(endpoint, path)
    return truncated_current if @current.present? && endpoint == endpoints.last

    return endpoint.titleize if endpoint.to_i.eql?(0)

    object = path.split("/")[-2]&.singularize
    record = instance_variable_get(:"@#{object}")

    record.try(:name) || endpoint
  end

  # Long enough to recognise the study, short enough that the trail stays one
  # line. Registry titles run to 300 characters.
  def truncated_current
    @current.to_s.truncate(60, separator: " ")
  end

  def path_exists?(path)
    Rails.application.routes.recognize_path(path)
    true
  rescue ActionController::RoutingError
    false
  end
end
