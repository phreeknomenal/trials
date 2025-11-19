class Page::Trials::TileComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="flex gap-2 items-start">
      <% if icon.present? %>
        <div class="w-5 h-5 mt-[3px] text-lavender-600">
          <%= render Utilities::IconComponent.new(icon, size: 16) %>
        </div>
      <% end %>
      <div>
        <h3 class="text-base font-semibold text-zinc-900 dark:text-zinc-300"><%= title %></h3>
        <p class="text-sm font-body text-zinc-600 dark:text-zinc-400">
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
