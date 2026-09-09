class Page::Trials::SortByComponent < ApplicationComponent
  def initialize(current_sort:, base_path:, pagination_params: {})
    @current_sort = current_sort
    @base_path = base_path
    @pagination_params = pagination_params
  end

  def sort_buttons
    [
      {
        label: "Sort by Match",
        sort_value: "score",
        active: @current_sort == "score"
      },
      {
        label: "Sort by Relevance",
        sort_value: nil,
        active: @current_sort.blank?
      }
    ]
  end

  def button_path(sort_value)
    params = if sort_value
      @pagination_params.merge(sort_by: sort_value)
    else
      @pagination_params.except(:sort_by)
    end
    helpers.url_for(controller: @base_path, action: :index, **params)
  end

  def button_classes(active)
    base = "px-3 py-2 text-sm rounded"
    if active
      "#{base} bg-sky-100 dark:bg-navy-900/30 text-sky-700 dark:text-sky-300"
    else
      "#{base} text-ink-3 dark:text-ink-3-on-dark hover:bg-surface-2 dark:hover:bg-surface-on-dark"
    end
  end
end
