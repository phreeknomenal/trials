module Admin
  class StatCardComponent < ApplicationComponent
    erb_template <<~ERB
      <div class="rounded-lg border <%= border_class %> p-4">
        <div class="text-xs font-medium uppercase tracking-wide text-ink-3 dark:text-ink-3-on-dark"><%= label %></div>
        <div class="mt-1 text-2xl font-bold <%= value_class %>"><%= value %></div>
        <% if hint.present? %>
          <div class="mt-1 text-xs text-ink-3 dark:text-ink-4-on-dark"><%= hint %></div>
        <% end %>
      </div>
    ERB

    attr_reader :label, :value, :hint, :tone

    # tone: :neutral or :alert. :alert is for numbers that mean something is
    # wrong -- failed jobs, stuck records -- and is suppressed when the value is
    # zero so a healthy dashboard is not covered in red.
    def initialize(label:, value:, hint: nil, tone: :neutral)
      @label = label
      @value = value
      @hint = hint
      @tone = tone
    end

    def alerting?
      tone == :alert && value.to_i.positive?
    end

    def border_class
      alerting? ? "border-crit/30 dark:border-crit-on-dark" : "border-line dark:border-line-on-dark"
    end

    def value_class
      alerting? ? "text-crit dark:text-crit-on-dark" : "text-ink dark:text-ink-on-dark"
    end
  end
end
