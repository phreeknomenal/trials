# The signed-in mobile navigation, pinned to the bottom of the viewport.
#
# From the "Dashboard and profile, mobile" board: "A tab bar replaces the top nav
# once signed in. My trials, Find, Saved, Profile, each a 44px target with a
# label." The board's signed-in phone header is the wordmark and the avatar and
# nothing else, so the hamburger goes with it.
#
# Signed out keeps the slide-over panel. Someone with no account has one task,
# searching, and a persistent four-tab bar would spend a fifth of a 390px screen
# on three destinations they have no use for yet.
#
# Labels are always visible, never icon-only. An icon alone is a guess, and the
# board asks for a label on every tab.
class Layout::Navigation::TabBarComponent < ApplicationComponent
  erb_template <<-ERB
    <% if show? %>
      <%# A spacer in the flow, the same height as the bar. Without it the bar
          covers the last of the page, and the thing it covers on the dashboard
          is the profile prompt. %>
      <div aria-hidden="true" class="h-20 lg:hidden"></div>

      <nav class="lg:hidden fixed bottom-0 inset-x-0 z-40
                  border-t border-line dark:border-line-on-dark
                  bg-surface dark:bg-surface-on-dark
                  px-3 pt-2 pb-4 flex justify-around"
           aria-label="Main">
        <% tabs.each do |label, path, icon| %>
          <%= link_to path, class: tab_class(path), aria: {current: ("page" if current?(path))} do %>
            <%= render Utilities::IconComponent.new(icon, size: 6) %>
            <span class="text-[11px] font-semibold leading-none"><%= label %></span>
          <% end %>
        <% end %>
      </nav>
    <% end %>
  ERB

  # min-h and min-w carry the 44px the board asks for. The visible content is
  # smaller than that, so without them the target would be about 38px and every
  # thumb would miss the edges.
  BASE_TAB_CLASS = "flex flex-col items-center justify-center gap-1 rounded-nav " \
    "min-h-11 min-w-11 px-3 py-1 transition-colors " \
    "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus"

  CURRENT_TAB_CLASS = "text-sky-700 dark:text-sky-300"

  RESTING_TAB_CLASS = "text-ink-4 dark:text-ink-4-on-dark hover:text-ink-2 dark:hover:text-ink-2-on-dark"

  # Profile is the only one that needs a record to link to. A signed-in user
  # without a saved profile is redirected into onboarding by
  # ApplicationController, so it cannot be reached without one -- but the bar
  # renders on any page using the signed-in layout, so this is guarded rather
  # than assumed.
  def tabs
    [
      ["My trials", helpers.my_trials_root_path, "home"],
      ["Find", helpers.search_index_path, "search"],
      ["Saved", helpers.saved_trials_path, "bookmark"],
      ["Profile", profile_path, "user_circle"]
    ]
  end

  def show?
    user_signed_in? && current_profile.present?
  end

  def tab_class(path)
    [BASE_TAB_CLASS, current?(path) ? CURRENT_TAB_CLASS : RESTING_TAB_CLASS].join(" ")
  end

  # Guarded the same way HeaderMenuComponent guards it: a component spec can
  # render without a request, and a nav that raises in test is worse than one
  # that marks nothing as current.
  def current?(path)
    helpers.current_page?(path)
  rescue ActionController::UrlGenerationError, ArgumentError
    false
  end

  private

  def profile_path
    helpers.profile_path(current_profile)
  end
end
