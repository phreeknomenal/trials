class Page::Navigation::BreadcrumbComponent < ApplicationComponent
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
    return endpoint.titleize if endpoint.to_i.eql?(0)

    object = path.split("/")[-2]&.singularize
    record = instance_variable_get(:"@#{object}")

    record.try(:name) || endpoint
  end

  def path_exists?(path)
    Rails.application.routes.recognize_path(path)
    true
  rescue ActionController::RoutingError
    false
  end
end
