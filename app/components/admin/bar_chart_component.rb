module Admin
  # Server-rendered bars. No charting dependency: the app uses importmap and has
  # no JS chart library, and this is a handful of counts.
  class BarChartComponent < ApplicationComponent
    erb_template <<~ERB
      <div class="space-y-2">
        <% series.each do |label, value| %>
          <div class="flex items-center gap-3">
            <div class="w-28 shrink-0 text-xs text-ink-3 dark:text-ink-3-on-dark truncate" title="<%= label %>"><%= label %></div>
            <div class="flex-1 h-5 rounded bg-surface-2 dark:bg-surface-on-dark overflow-hidden">
              <div class="h-full rounded bg-navy-500" style="width: <%= percent_for(value) %>%"></div>
            </div>
            <div class="w-10 shrink-0 text-right text-xs font-medium text-ink-2 dark:text-ink-2-on-dark"><%= value %></div>
          </div>
        <% end %>
        <% if series.empty? %>
          <p class="text-sm text-ink-3 dark:text-ink-4-on-dark"><%= empty_message %></p>
        <% end %>
      </div>
    ERB

    attr_reader :series, :empty_message

    def initialize(series:, empty_message: "No data yet.")
      @series = series.to_a
      @empty_message = empty_message
    end

    def maximum
      @maximum ||= series.map { |_, value| value.to_i }.max.to_i
    end

    # Guarded: production currently has one user and zero saved trials, so an
    # all-zero series is the normal case, not an edge.
    def percent_for(value)
      return 0 if maximum.zero?

      ((value.to_f / maximum) * 100).round
    end
  end
end
