# The same links in both the desktop bar and the mobile panel, so nothing is
# reachable on one and not the other. Orientation only changes layout classes.
class Layout::Navigation::Menu::HeaderMenuComponent < ApplicationComponent
  erb_template <<-ERB
    <nav class="<%= container_class %>" aria-label="Main">
      <% links.each do |name, path| %>
        <%= link_to name, path,
              class: link_class(path),
              aria: {current: ("page" if current?(path))} %>
      <% end %>
    </nav>
  ERB

  BASE_LINK_CLASS = "rounded-nav px-3 py-2 font-medium transition-colors " \
    "hover:bg-surface-2 hover:text-ink " \
    "dark:hover:bg-surface-on-dark dark:hover:text-ink-on-dark " \
    "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-500"

  CURRENT_LINK_CLASS = "bg-sky-50 text-sky-700 dark:bg-navy-900/30 dark:text-sky-300"

  RESTING_LINK_CLASS = "text-ink-2 dark:text-ink-2-on-dark"

  def initialize(orientation: :horizontal)
    @orientation = orientation
  end

  # There used to be two search links, "My Trial Search" and "Browse All Trials",
  # pointing at two controllers that did the same job. One search now, which scores
  # against your profile when you have one, so there is nothing left to choose
  # between.
  def links
    if user_signed_in?
      {
        "My trials" => helpers.my_trials_root_path,
        "Find trials" => helpers.search_index_path,
        "Saved" => helpers.saved_trials_path
      }
    else
      {"Find trials" => helpers.search_index_path}
    end
  end

  def container_class
    if vertical?
      "flex flex-col gap-1 text-base tracking-tight"
    else
      "flex items-center gap-1 text-base tracking-tight"
    end
  end

  def link_class(path)
    state = current?(path) ? CURRENT_LINK_CLASS : RESTING_LINK_CLASS
    width = vertical? ? "block" : ""

    [BASE_LINK_CLASS, state, width].reject(&:blank?).join(" ")
  end

  # Guarded because a component spec can render without a request, and a nav
  # that raises in test is worse than one that renders nothing as current.
  def current?(path)
    helpers.current_page?(path)
  rescue ActionController::UrlGenerationError, ArgumentError
    false
  end

  private

  def vertical?
    @orientation == :vertical
  end
end
