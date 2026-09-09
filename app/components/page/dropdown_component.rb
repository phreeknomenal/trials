class Page::DropdownComponent < ApplicationComponent
  erb_template <<-ERB
    <details class="border border-line-2 dark:border-line-on-dark rounded-lg overflow-hidden">
      <summary class="cursor-pointer px-4 py-3 font-medium text-ink dark:text-ink-on-dark hover:bg-sky-50 dark:hover:bg-navy-500">
        <%= title %>
      </summary>
      <div class="p-6 border-t border-line-2 dark:border-line-on-dark text-ink-3 dark:text-ink-3-on-dark max-w-none bg-surface-2 dark:bg-surface-on-dark">
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
