class Page::Trials::HeaderComponent < ApplicationComponent
  erb_template <<-ERB
    <section class="px-5 lg:px-44 py-12 border-b border-zinc-200 dark:border-zinc-700">
      <div class="flex flex-col gap-4">
        <div class="flex items-start justify-between">
          <div class="">
            <%= render Utilities::BadgeComponent.new(status: study[:status], size: :md) %>
          </div>
          <% if saved_trial_available? && user_signed_in? && nct_id.present? %>
            <div>
              <%= render Buttons::SaveTrialButtonComponent.new(
                nct_id: nct_id,
                trial_title: study[:title],
                saved_trial: saved_trial,
                size: "md",
                trial_data: study,
                match_score: match_score
              ) %>
            </div>
          <% end %>
        </div>

        <h1 class="text-3xl lg:text-4xl font-bold text-zinc-900 dark:text-zinc-100">
          <%= study[:title] %>
        </h1>

        <div class="flex flex-wrap gap-4 text-sm text-zinc-600 dark:text-zinc-400">
          <div class="flex items-center gap-1">
            <%= render Utilities::IconComponent.new("profile_card", size: 6) %>
            <span><strong>NCT-ID:</strong> <%= nct_id %></span>
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

  attr_reader :study, :saved_trial, :nct_id, :match_score

  def initialize(study:, saved_trial: nil, nct_id: nil, match_score: nil)
    @study = study
    @saved_trial = saved_trial
    @nct_id = nct_id
    @match_score = match_score
  end

  def saved_trial_available?
    @study.present? && @nct_id.present?
  end
end
