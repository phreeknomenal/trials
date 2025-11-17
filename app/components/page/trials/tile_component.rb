class Page::Trials::TileComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="bg-zinc-50 dark:bg-zinc-800 rounded-lg px-5 py-3">
      <h3 class="text-base font-semibold text-zinc-900 dark:text-zinc-300 mb-1"><%= title %></h3>
      <p class="text-sm font-body text-zinc-600 dark:text-zinc-400">
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
