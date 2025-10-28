class Layout::Navigation::Menu::HeaderMenuComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="text-base font-medium tracking-tight flex items-center gap-4">
      <%= link_to "Home", root_path %>
      <%= link_to "Browse Trials", "#" %>
      <%= link_to "Contact", "#" %>
    </div>
  ERB
end
