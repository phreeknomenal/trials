module Admin
  class StatCardComponent < ApplicationComponent
    erb_template <<~ERB
      <div class="rounded-lg border <%= border_class %> p-4">
        <div class="text-xs font-medium uppercase tracking-wide text-zinc-500 dark:text-zinc-400"><%= label %></div>
        <div class="mt-1 text-2xl font-bold <%= value_class %>"><%= value %></div>
        <% if hint.present? %>
          <div class="mt-1 text-xs text-zinc-500 dark:text-zinc-500"><%= hint %></div>
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
      alerting? ? "border-red-300 dark:border-red-800" : "border-zinc-200 dark:border-zinc-700"
    end

    def value_class
      alerting? ? "text-red-700 dark:text-red-300" : "text-zinc-900 dark:text-zinc-100"
    end
  end
end
