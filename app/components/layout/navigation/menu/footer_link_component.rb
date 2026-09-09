class Layout::Navigation::Menu::FooterLinkComponent < ApplicationComponent
  erb_template <<-ERB
    <ul class="space-y-2 text-ink-3">
      <h3 class="text-xl font-semibold mb-2 text-ink dark:text-ink-2-on-dark">Company</h3>
      <li>About Us</li>
      <li>Our Stories</li>
      <% if user_signed_in? %>
        <li><%= link_to "Sign Out", destroy_user_session_path, method: :delete, class: "text-crit"  %></li>
      <% else %>
        <li><%= link_to "Sign In", new_user_session_path, class: "text-sky-600" %></li>
        <li><%= link_to "Sign Up", new_user_registration_path, class: "text-sky-600" %></li>
      <% end %>
    </ul>
    <ul class="space-y-2 text-ink-3">
      <h3 class="text-xl font-semibold mb-2 text-ink dark:text-ink-2-on-dark">Support</h3>
      <li>FAQ</li>
      <li>Membership</li>
      <li>User Policy</li>
      <li>Customer Support</li>
    </ul>
    <ul class="space-y-2 text-ink-3">
      <h3 class="text-xl font-semibold mb-2 text-ink dark:text-ink-2-on-dark">Contact</h3>
      <li>Facebook</li>
      <li>Instagram</li>
      <li>Twitter</li>
      <li>LinkedIn</li>
      <li>Email</li>
    </ul>
  ERB
end
