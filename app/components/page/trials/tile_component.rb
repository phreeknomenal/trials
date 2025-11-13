class Page::Trials::TileComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="bg-zinc-50 dark:bg-zinc-800 rounded-lg p-3">
      <h3 class="text-sm font-medium text-zinc-500 dark:text-zinc-400 mb-1"><%= title %></h3>
      <p class="text-base font-body font-semibold text-zinc-900 dark:text-zinc-300">
        <%= record %>
      </p>
    </div>
  ERB

  attr_reader :title, :record

  def initialize(title:, record:)
    @title = title
    @record = record
  end
end
