class Layout::Navigation::Menu::FooterLinkComponent < ApplicationComponent
  erb_template <<-ERB
    <ul class="space-y-2">
      <h3 class="text-xl font-semibold mb-2">Company</h3>
      <li>About Us</li>
      <li>Our Stories</li>
      <% if user_signed_in? %>
        <li><%= link_to "Sign Out", destroy_user_session_path, method: :delete, class: "text-red-500"  %></li>
      <% else %>
        <li><%= link_to "Sign In", new_user_session_path, class: "text-lime-500" %></li>
        <li><%= link_to "Sign Up", new_user_registration_path, class: "text-lime-500" %></li>
      <% end %>
    </ul>
    <ul class="space-y-2">
      <h3 class="text-xl font-semibold mb-2">Support</h3>
      <li>FAQ</li>
      <li>Membership</li>
      <li>User Policy</li>
      <li>Customer Support</li>
    </ul>
    <ul class="space-y-2">
      <h3 class="text-xl font-semibold mb-2">Contact</h3>
      <li>Facebook</li>
      <li>Instagram</li>
      <li>Twitter</li>
      <li>LinkedIn</li>
      <li>Email</li>
    </ul>
  ERB
end
