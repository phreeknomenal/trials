class Page::Trials::Sidebar::ContainerComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="w-full flex flex-col p-6 space-y-2 text-base font-semibold text-ink dark:text-ink-2-on-dark border border-line-2 dark:border-line-on-dark rounded-lg">
      <%= content %>
    </div>
  ERB
end
