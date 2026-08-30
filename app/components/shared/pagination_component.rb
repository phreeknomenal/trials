module Shared
  # Prev/next controls plus a position indicator. URL construction stays at the
  # call site through path_for, since each page paginates a different route.
  #
  #   render Shared::PaginationComponent.new(pagy: @pagy, path_for: ->(page) { admin_users_path(page: page) })
  class PaginationComponent < ApplicationComponent
    erb_template <<~ERB
      <nav class="mt-6 flex items-center justify-between text-sm" aria-label="Pagination">
        <div class="w-24">
          <% if previous_page %>
            <%= link_to "← Previous", path_for.call(previous_page),
                  class: "text-lavender-600 hover:text-lavender-700 font-medium",
                  rel: "prev" %>
          <% end %>
        </div>

        <span class="text-zinc-500 dark:text-zinc-400">
          Page <%= pagy.page %> of <%= pagy.pages %><%= count_suffix %>
        </span>

        <div class="w-24 text-right">
          <% if next_page %>
            <%= link_to "Next →", path_for.call(next_page),
                  class: "text-lavender-600 hover:text-lavender-700 font-medium",
                  rel: "next" %>
          <% end %>
        </div>
      </nav>
    ERB

    attr_reader :pagy, :path_for, :unit

    def initialize(pagy:, path_for:, unit: nil)
      @pagy = pagy
      @path_for = path_for
      @unit = unit
    end

    # Nothing to navigate to, so render nothing at all rather than a control
    # that says "Page 1 of 1".
    def render?
      pagy.present? && pagy.pages > 1
    end

    # Pagy 43 renamed prev to previous. Wrapping both here means call sites
    # never touch the renamed API directly.
    def previous_page
      pagy.previous
    end

    def next_page
      pagy.next
    end

    def count_suffix
      return "" if unit.blank?

      " (#{pagy.count} #{unit.to_s.pluralize(pagy.count)})"
    end
  end
end
