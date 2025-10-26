class Layout::Navigation::Menu::HeaderMenuComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="text-sm font-light tracking-tight flex items-center gap-4">
      <%= link_to "Home", root_path %>
      <%= link_to "Browse Trials", "#" %>
      <%= link_to "Contact", "#" %>
      <%= link_to "Login", "#", class: "bg-blue-500 text-white px-4 py-2 rounded-md" %>
    </div>
  ERB
end
