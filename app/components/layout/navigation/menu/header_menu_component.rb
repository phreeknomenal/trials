class Layout::Navigation::Menu::HeaderMenuComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="text-base font-medium tracking-tight flex items-center gap-4 text-zinc-900 dark:text-zinc-300">
      <% if user_signed_in? %>
        <%= link_to "My Trial Search", my_trials_path, class: "hover:text-lavender-600" %>
        <%= link_to "Browse All Trials", search_index_path, class: "hover:text-lavender-600" %>
      <% else %>
        <%= link_to "Search Trials", search_index_path, class: "hover:text-lavender-600" %>
      <% end %>
      <%= link_to "Community", "#", class: "hover:text-lavender-600" %>
    </div>
  ERB
end
