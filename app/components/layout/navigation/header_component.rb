class Layout::Navigation::HeaderComponent < ApplicationComponent
  erb_template <<-ERB
    <header class="border-b border-line dark:border-line-on-dark"
            data-controller="mobile-menu"
            data-action="keydown.esc@window->mobile-menu#closeOnEscape click@window->mobile-menu#closeOnOutsideClick">

      <div class="<%= Layout::PageWidth::CONTAINER %> flex items-center justify-between gap-4 py-4">
        <div>
          <%= link_to root_path, class: "flex items-center gap-2 rounded-nav focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-500" do %>
            <%= render Utilities::MarkComponent.new(height: 8) %>
            <span class="font-primary text-2xl font-extrabold tracking-tight text-ink dark:text-ink-2-on-dark">Dira<span class="font-light text-ink-3 dark:text-ink-3-on-dark"> Health</span></span>
          <% end %>
        </div>

        <div class="hidden lg:flex items-center gap-3">
          <%= render Layout::Navigation::Menu::HeaderMenuComponent.new %>
          <%# The board puts a hairline between navigating the site and acting on
              your account. Without it a text nav link and a text Log in read as
              one list of six equal things. %>
          <span aria-hidden="true" class="w-px h-6 bg-line dark:bg-line-on-dark"></span>
          <%= render Buttons::DarkModeToggleComponent.new %>
          <%= render_account_control %>
        </div>

        <%# Signed in, the tab bar carries navigation and this goes with the
            board's phone header, which is the wordmark and the avatar and
            nothing else. Signed out keeps the panel: one task, and a permanent
            four-tab bar would spend a fifth of a 390px screen on destinations
            an account holder has and a visitor does not. %>
        <div class="lg:hidden flex items-center gap-2">
          <% if tab_bar? %>
            <%= render Buttons::DarkModeToggleComponent.new %>
            <%= render_account_control %>
          <% end %>
        </div>

        <% unless tab_bar? %>
        <button type="button"
                class="lg:hidden inline-flex items-center justify-center w-10 h-10 rounded-flash text-ink-2 dark:text-ink-2-on-dark hover:bg-surface-2 dark:hover:bg-surface-on-dark transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-500"
                data-mobile-menu-target="trigger"
                data-action="mobile-menu#toggle"
                aria-controls="mobile-menu-panel"
                aria-expanded="false"
                aria-label="Open menu">
          <span data-mobile-menu-target="openIcon">
            <%= render Utilities::IconComponent.new("bars", size: 6) %>
          </span>
          <span data-mobile-menu-target="closeIcon" class="hidden">
            <%= render Utilities::IconComponent.new("close", size: 6) %>
          </span>
        </button>
        <% end %>
      </div>

      <% unless tab_bar? %>
      <div id="mobile-menu-panel"
           data-mobile-menu-target="panel"
           hidden
           class="lg:hidden border-t border-line dark:border-line-on-dark">
        <div class="<%= Layout::PageWidth::CONTAINER %> py-4 flex flex-col gap-4">
          <%= render Layout::Navigation::Menu::HeaderMenuComponent.new(orientation: :vertical) %>

          <%# Stacked on the panel. Two buttons and the dark toggle in one row
              at 390px leaves each of them under the 44px target the mobile
              board asks for. %>
          <div class="flex flex-col gap-4 border-t border-line dark:border-line-on-dark pt-4">
            <%= render_account_control(stacked: true) %>
            <div class="flex items-center justify-between gap-4">
              <span class="text-sm font-medium text-ink-2 dark:text-ink-2-on-dark">Dark mode</span>
              <%= render Buttons::DarkModeToggleComponent.new %>
            </div>
          </div>
        </div>
      </div>
      <% end %>
    </header>
  ERB

  # Rendered in both the desktop bar and the mobile panel, so a signed out user
  # on a phone still has a way in.
  #
  # Signed out gets two controls, not one. The header offered Login only, so the
  # single most valuable action a first-time visitor can take was reachable from
  # the footer and from nowhere else above the fold. The board has both, with
  # sign up carrying the filled button and log in the quiet one, because someone
  # who already has an account will look for it and someone who does not needs
  # to be shown.
  #
  # The classes come from Buttons::ButtonStyles rather than being written here.
  # This method used to hand-roll a navy button, which is how the header's Login
  # drifted to a different radius and hover from every other primary button.
  # True where Layout::Navigation::TabBarComponent renders, so the two agree
  # about who carries navigation at phone width. Both ask the same question of
  # the same two helpers rather than one inferring the other.
  def tab_bar?
    user_signed_in? && current_profile.present?
  end

  def render_account_control(stacked: false)
    return profile_link if user_signed_in?

    tag.div(class: stacked ? "flex flex-col gap-2 w-full" : "flex items-center gap-2") do
      safe_join([
        link_to("Log in", helpers.new_user_session_path, class: Buttons::ButtonStyles.classes("quiet")),
        link_to("Sign up free", helpers.new_user_registration_path, class: Buttons::ButtonStyles.classes("primary"))
      ])
    end
  end

  private

  def profile_link
    link_to helpers.profile_path(current_profile),
      class: "block w-10 h-10 rounded-full overflow-hidden focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus",
      aria: {label: "Your profile"} do
      render Utilities::AvatarComponent.new(avatar: current_profile.avatar, initials: current_profile.initials, size: 40)
    end
  end
end
