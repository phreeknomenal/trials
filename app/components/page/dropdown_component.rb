class Page::DropdownComponent < ApplicationComponent
  erb_template <<-ERB
    <details class="border border-zinc-300 dark:border-zinc-700 rounded-lg overflow-hidden">
      <summary class="cursor-pointer px-4 py-3 font-medium text-zinc-900 dark:text-zinc-100 hover:bg-lavender-50 dark:hover:bg-lavender-500">
        <%= title %>
      </summary>
      <div class="p-6 border-t border-zinc-300 dark:border-zinc-700 text-zinc-600 dark:text-zinc-400 max-w-none bg-zinc-50 dark:bg-zinc-800">
        <%= simple_format(body) %>
      </div>
    </details>
  ERB

  attr_reader :title, :body

  def initialize(title:, body:)
    @title = title
    @body = body
  end
end
