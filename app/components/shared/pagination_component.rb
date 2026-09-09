module Shared
  # Prev/next controls plus a position indicator. URL construction stays at the
  # call site through path_for, since each page paginates a different route.
  #
  #   render Shared::PaginationComponent.new(pagy: @pagy, path_for: ->(page) { admin_users_path(page: page) })
  class PaginationComponent < ApplicationComponent
    erb_template <<~ERB
      <nav class="mt-6 flex items-center justify-between gap-4 border-t border-line dark:border-line-on-dark pt-4 text-sm" aria-label="Pagination">
        <% if previous_page %>
          <%= link_to path_for.call(previous_page), rel: "prev", class: link_classes do %>
            <%= render Utilities::IconComponent.new("chevron_left", size: 4) %>
            Previous
          <% end %>
        <% else %>
          <span class="\#{link_classes} opacity-40 pointer-events-none" aria-disabled="true">
            <%= render Utilities::IconComponent.new("chevron_left", size: 4) %>
            Previous
          </span>
        <% end %>

        <span class="text-ink-3 dark:text-ink-3-on-dark tabular-nums">
          Page <%= pagy.page %> of <%= pagy.pages %><%= count_suffix %>
        </span>

        <% if next_page %>
          <%= link_to path_for.call(next_page), rel: "next", class: link_classes do %>
            Next
            <%= render Utilities::IconComponent.new("chevron_right", size: 4) %>
          <% end %>
        <% else %>
          <span class="\#{link_classes} opacity-40 pointer-events-none" aria-disabled="true">
            Next
            <%= render Utilities::IconComponent.new("chevron_right", size: 4) %>
          </span>
        <% end %>
      </nav>
    ERB

    # Both ends are always rendered, disabled rather than absent, so the page
    # indicator stays centred instead of sliding as you reach either end.
    LINK_CLASSES = "inline-flex items-center gap-1 rounded-md px-2 py-1 font-semibold " \
      "text-sky-600 dark:text-sky-300 hover:bg-sky-50 dark:hover:bg-navy-900/30 " \
      "transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 " \
      "focus-visible:outline-sky-500"

    def link_classes
      LINK_CLASSES
    end

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
