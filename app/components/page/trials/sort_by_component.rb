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
    params = sort_value ? @pagination_params.merge(sort_by: sort_value) : @pagination_params
    helpers.url_for(controller: @base_path, action: :index, **params)
  end

  def button_classes(active)
    base = "px-3 py-2 text-sm rounded"
    if active
      "#{base} bg-lavender-100 dark:bg-lavender-900/30 text-lavender-700 dark:text-lavender-300"
    else
      "#{base} text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800"
    end
  end
end
