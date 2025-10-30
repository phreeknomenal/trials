class Layout::Navigation::HeaderComponent < ApplicationComponent
  erb_template <<-ERB
    <header class="border-b border-zinc-200">
      <div class="w-[80%] mx-auto flex items-center justify-between py-4">
        <div>
          <%= link_to root_path, class: "font-primary text-2xl font-bold tracking-tight" do %>
            Clinical Trial Finder
          <% end %>
        </div>

        <div class="hidden lg:flex items-center gap-4">
          <%= render Layout::Navigation::Menu::HeaderMenuComponent.new %>
          <% if user_signed_in? %>
            <div class="w-10 h-10 rounded-full overflow-hidden">
              <%= render Utilities::AvatarComponent.new(current_profile) %>
            </div>
          <% else %>
            <%= link_to "Login", new_user_session_path, class: "bg-lavender-600 text-white px-4 py-2 font-medium rounded-md" %>
          <% end %>
        </div>
      </div>
    </header>
  ERB
end
