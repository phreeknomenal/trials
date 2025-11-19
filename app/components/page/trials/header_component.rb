class Page::Trials::HeaderComponent < ApplicationComponent
  erb_template <<-ERB
    <section class="px-5 lg:px-44 py-12 border-b border-zinc-200 dark:border-zinc-700">
      <div class="flex flex-col gap-4">
        <div class="">
          <%= render Utilities::BadgeComponent.new(status: study[:status], size: :md) %>
        </div>

        <h1 class="text-3xl lg:text-4xl font-bold text-zinc-900 dark:text-zinc-100">
          <%= study[:title] %>
        </h1>

        <div class="flex flex-wrap gap-4 text-sm text-zinc-600 dark:text-zinc-400">
          <div class="flex items-center gap-1">
            <%= render Utilities::IconComponent.new("profile_card", size: 6) %>
            <span><strong>NCT-ID:</strong> <%= @study[:nct_id] %></span>
          </div>
          <% if @study[:phase].present? %>
            <div class="flex items-center gap-1">
              <%= render Utilities::IconComponent.new("beaker", size: 6) %>
              <span><strong>Phase:</strong> <%= @study[:phase] %></span>
            </div>
          <% end %>
        </div>
      </div>
    </section>
  ERB

  attr_reader :study

  def initialize(study:)
    @study = study
  end
end
