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

  BASE_LINK_CLASS = "rounded-nav px-3 py-2 transition-colors " \
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
  # About and FAQ are in the signed-out bar and not the signed-in one. A visitor
  # deciding whether to trust the app needs them within reach; someone already
  # signed in is here to work, and pushing their three task links along to make
  # room for two reference pages gets the priority backwards. Both stay in the
  # footer on every page, which is where a reference link belongs.
  def links
    if user_signed_in?
      {
        "My trials" => helpers.my_trials_root_path,
        "Find trials" => helpers.search_index_path,
        "Saved" => helpers.saved_trials_path
      }
    else
      {
        "Find trials" => helpers.search_index_path,
        "About" => helpers.about_path,
        "FAQ" => helpers.faq_path
      }
    end
  end

  # 14px semibold in the bar, per the board. It was 16px medium, which put a nav
  # link at the same optical weight as body copy and made the bar the loudest
  # thing on every page.
  #
  # The panel keeps 17px, also per the board: a tap target read at arm's length
  # is not the same problem as a link read in a dense row.
  def container_class
    if vertical?
      "flex flex-col gap-1 text-[17px] tracking-tight"
    else
      "flex items-center gap-1 text-sm font-semibold tracking-tight"
    end
  end

  # The panel's links get py-3 rather than the bar's py-2. At 17px text that is
  # 12 + 26 + 12, so a tap target clears the 44px floor the mobile board sets;
  # py-2 leaves it at about 42px. In the bar it is a pointer, not a thumb.
  VERTICAL_LINK_CLASS = "block py-3"

  def link_class(path)
    state = current?(path) ? CURRENT_LINK_CLASS : RESTING_LINK_CLASS
    size = vertical? ? VERTICAL_LINK_CLASS : nil

    [BASE_LINK_CLASS, state, size].compact.join(" ")
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
