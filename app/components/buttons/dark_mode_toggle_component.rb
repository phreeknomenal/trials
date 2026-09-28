# on_dark for chrome that is dark whatever the theme is. The admin bar is navy
# in light mode too, so the ordinary ink-2 icon would be a dark grey glyph on a
# near-black bar: the same invisible control ButtonStyles records for the
# landing page's call to action.
class Buttons::DarkModeToggleComponent < ApplicationComponent
  erb_template <<-ERB
    <div data-controller="dark-mode">
      <button
        type="button"
        data-action="click->dark-mode#toggle"
        class="relative inline-flex items-center justify-center w-10 h-10 rounded-full <%= hover_class %> transition-colors duration-200"
        aria-label="Toggle dark mode"
      >
        <!-- Moon Icon (visible in light mode) -->
        <svg
          data-dark-mode-target="moonIcon"
          class="w-5 h-5 <%= icon_class %>"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
          />
        </svg>

        <!-- Sun Icon (visible in dark mode) -->
        <svg
          data-dark-mode-target="sunIcon"
          class="w-5 h-5 <%= icon_class %> hidden"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
          />
        </svg>
      </button>
    </div>
  ERB

  def initialize(on_dark: false)
    @on_dark = on_dark
  end

  def on_dark? = @on_dark

  def icon_class
    on_dark? ? "text-ink-3-on-dark" : "text-ink-2 dark:text-ink-2-on-dark"
  end

  def hover_class
    on_dark? ? "hover:bg-line-on-dark" : "hover:bg-surface-2 dark:hover:bg-surface-on-dark"
  end
end
