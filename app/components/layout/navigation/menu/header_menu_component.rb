class Layout::Navigation::Menu::HeaderMenuComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="text-base font-medium tracking-tight flex items-center gap-4 text-zinc-900 dark:text-zinc-300">
      <%= link_to "Find Trials", "#" %>
      <%= link_to "Learn", "#" %>
      <%= link_to "Community", "#" %>
    </div>
  ERB
end
