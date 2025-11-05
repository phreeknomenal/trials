class Layout::Navigation::Menu::HeaderMenuComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="text-base font-medium tracking-tight flex items-center gap-4 text-zinc-900 dark:text-zinc-300">
      <%= link_to "Search", search_index_path %>
      <%= link_to "My Trials", my_trials_path %>
      <%= link_to "Community", "#" %>
    </div>
  ERB
end
