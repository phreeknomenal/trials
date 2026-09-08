class Layout::Navigation::HeaderComponent < ApplicationComponent
  erb_template <<-ERB
    <header class="border-b border-zinc-200 dark:border-zinc-700"
            data-controller="mobile-menu"
            data-action="keydown.esc@window->mobile-menu#closeOnEscape click@window->mobile-menu#closeOnOutsideClick">

      <div class="mx-auto w-full max-w-6xl px-4 sm:px-6 lg:px-8 flex items-center justify-between gap-4 py-4">
        <div>
          <%= link_to root_path, class: "flex items-center gap-2 rounded-md focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-500" do %>
            <%= render Utilities::MarkComponent.new(height: 8) %>
            <span class="font-primary text-2xl font-extrabold tracking-tight text-zinc-900 dark:text-zinc-300">Dira<span class="font-light text-zinc-500 dark:text-zinc-400"> Health</span></span>
          <% end %>
        </div>

        <div class="hidden lg:flex items-center gap-4">
          <%= render Layout::Navigation::Menu::HeaderMenuComponent.new %>
          <%= render Buttons::DarkModeToggleComponent.new %>
          <%= render_account_control %>
        </div>

        <button type="button"
                class="lg:hidden inline-flex items-center justify-center w-10 h-10 rounded-md text-zinc-700 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-500"
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
      </div>

      <div id="mobile-menu-panel"
           data-mobile-menu-target="panel"
           hidden
           class="lg:hidden border-t border-zinc-200 dark:border-zinc-700">
        <div class="mx-auto w-full max-w-6xl px-4 sm:px-6 py-4 flex flex-col gap-4">
          <%= render Layout::Navigation::Menu::HeaderMenuComponent.new(orientation: :vertical) %>

          <div class="flex items-center justify-between gap-4 border-t border-zinc-200 dark:border-zinc-700 pt-4">
            <%= render Buttons::DarkModeToggleComponent.new %>
            <%= render_account_control %>
          </div>
        </div>
      </div>
    </header>
  ERB

  # Rendered in both the desktop bar and the mobile panel, so a signed out user
  # on a phone still has a way in.
  def render_account_control
    if user_signed_in?
      link_to helpers.profile_path(current_profile),
        class: "block w-10 h-10 rounded-full overflow-hidden focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-500",
        aria: {label: "Your profile"} do
        render Utilities::AvatarComponent.new(avatar: current_profile.avatar, initials: current_profile.initials)
      end
    else
      link_to "Login", helpers.new_user_session_path,
        class: "bg-navy-600 text-white px-4 py-2 font-medium rounded-md hover:bg-navy-700 transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-500"
    end
  end
end
