class Page::Trials::Sidebar::ContainerComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="w-full flex flex-col p-6 space-y-2 text-base font-semibold text-zinc-900 dark:text-zinc-300 border border-zinc-300 dark:border-zinc-700 rounded-lg">
      <%= content %>
    </div>
  ERB
end
