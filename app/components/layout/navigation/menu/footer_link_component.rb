# The footer's link columns.
#
# They were not links. Every entry was a bare <li> holding text: "About Us",
# "FAQ", "User Policy", "Customer Support", "Facebook", "Instagram", "Twitter",
# "LinkedIn", "Email". Nine advertised destinations, none of them clickable, and
# four of them naming pages that did not exist in the app at all.
#
# Now every entry is a real link to a real route. The rule this file follows,
# and the reason it is shorter than what it replaced: a footer names the places
# you can go. Something with nowhere to point is not a quiet placeholder, it is
# a dead end that looks like a way out.
#
# Deliberately gone, rather than left as text:
#
#   - Our Stories, Membership, Customer Support: no such feature, and no plan
#     for one. Contact covers the last of them
#   - User Policy: terms of service do not exist. When they do they go beside
#     Privacy
#   - The five social entries: no account exists on any of those networks
class Layout::Navigation::Menu::FooterLinkComponent < ApplicationComponent
  erb_template <<-ERB
    <% columns.each do |heading, links| %>
      <div>
        <h3 class="text-xl font-semibold mb-2 text-ink dark:text-ink-2-on-dark"><%= heading %></h3>
        <ul class="space-y-2">
          <% links.each do |label, path, extra| %>
            <li>
              <%= link_to label, path, class: link_class(extra) %>
            </li>
          <% end %>
        </ul>
      </div>
    <% end %>
  ERB

  LINK_CLASS = "text-ink-3 dark:text-ink-3-on-dark hover:text-ink dark:hover:text-ink-on-dark " \
    "hover:underline underline-offset-4 transition-colors " \
    "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus rounded-nav"

  def columns
    {
      "Company" => [
        ["About us", helpers.about_path],
        ["Contact", helpers.contact_path]
      ],
      "Help" => [
        ["FAQ", helpers.faq_path],
        ["Privacy", helpers.privacy_path],
        ["Find trials", helpers.search_index_path]
      ],
      "Account" => account_links
    }
  end

  def link_class(extra = nil)
    [LINK_CLASS, extra].compact.join(" ")
  end

  private

  def account_links
    if user_signed_in?
      [
        ["My trials", helpers.my_trials_root_path],
        ["Saved studies", helpers.saved_trials_path],
        ["Account settings", helpers.edit_user_registration_path],
        ["Sign out", helpers.destroy_user_session_path, "text-crit dark:text-crit-on-dark"]
      ]
    else
      [
        ["Sign in", helpers.new_user_session_path, "text-sky-600 dark:text-sky-300"],
        ["Sign up", helpers.new_user_registration_path, "text-sky-600 dark:text-sky-300"]
      ]
    end
  end
end
