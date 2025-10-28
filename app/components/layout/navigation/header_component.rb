class Layout::Navigation::HeaderComponent < ApplicationComponent
  erb_template <<-ERB
    <header class="border-b border-zinc-200">
      <div class="w-[80%] mx-auto flex items-center justify-between py-4">
        <div>
          <h1 class="text-2xl font-bold tracking-tight">Clinical Trial Finder</h1>
        </div>
        <div class="flex items-center gap-4">
          <%= render Layout::Navigation::Menu::HeaderMenuComponent.new %>
          <% if user_signed_in? %>
            <div class="w-10 h-10 rounded-full overflow-hidden">
              <%= render Utilities::AvatarComponent.new(current_profile) %>
            </div>
          <% else %>
            <%= link_to "Login", new_user_session_path, class: "bg-blue-500 text-white px-4 py-2 font-medium rounded-md" %>
          <% end %>
        </div>
      </div>
    </header>
  ERB
end
