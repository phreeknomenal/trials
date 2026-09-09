class Page::Trials::TileComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="flex gap-2 items-start">
      <% if icon.present? %>
        <div class="w-5 h-5 mt-[3px] text-sky-600">
          <%= render Utilities::IconComponent.new(icon, size: 5) %>
        </div>
      <% end %>
      <div>
        <h3 class="text-base font-semibold text-ink dark:text-ink-2-on-dark"><%= title %></h3>
        <p class="text-sm font-body text-ink-3 dark:text-ink-3-on-dark">
          <%= record %>
        </p>
      </div>
    </div>
  ERB

  attr_reader :title, :record, :icon

  def initialize(title:, record:, icon: nil)
    @title = title
    @record = record
    @icon = icon
  end
end
