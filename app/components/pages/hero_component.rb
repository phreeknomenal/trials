# The banded heading at the top of a content page: eyebrow, headline, a lead
# paragraph, and the same gradient and shapes the auth and onboarding panels
# use, so these pages read as part of the app rather than as a separate site.
#
# The backdrop partial is shared rather than copied. Three pages carrying their
# own inline SVG is three chances for one of them to drift.
class Pages::HeroComponent < ApplicationComponent
  erb_template <<-ERB
    <header class="relative overflow-hidden border-b border-line dark:border-line-on-dark
                   bg-[linear-gradient(180deg,#EDF2FB_0%,#F6F9FD_55%,#FFFFFF_100%)]
                   dark:bg-none dark:bg-surface-on-dark">
      <%# Landscape geometry and a landscape view_box. The default 620x920 is a
          tall auth panel; sliced into a hero band it scales by nearly three and
          every shape lands off screen. %>
      <div aria-hidden="true" class="hidden md:block dark:hidden">
        <%= render "shared/panel_backdrop", id: backdrop_id, view_box: "0 0 1440 420",
              blob_x: 1270, blob_y: 70, blob_r: 200,
              pill_y: 150, pill_w: 240, pill_h: 300,
              dots_x: 1030, dots_y: 250, dot_x: 150, dot_y: 90 %>
      </div>

      <div class="relative <%= Layout::PageWidth::CONTAINER %> py-14 lg:py-20 flex flex-col gap-4">
        <p class="text-xs font-bold uppercase tracking-[0.09em] text-sky-600 dark:text-sky-300"><%= eyebrow %></p>
        <h1 class="font-primary text-4xl lg:text-5xl font-extrabold tracking-tight text-ink dark:text-ink-on-dark max-w-3xl">
          <%= heading %>
        </h1>
        <% if lead.present? %>
          <p class="text-lg leading-relaxed text-ink-3 dark:text-ink-3-on-dark max-w-2xl"><%= lead %></p>
        <% end %>
        <% if content.present? %>
          <div class="mt-2"><%= content %></div>
        <% end %>
      </div>
    </header>
  ERB

  attr_reader :eyebrow, :heading, :lead

  def initialize(eyebrow:, heading:, lead: nil)
    @eyebrow = eyebrow
    @heading = heading
    @lead = lead
  end

  # The backdrop's gradient and pattern ids have to be unique per render, or a
  # second one on the same page would reuse the first's definitions.
  def backdrop_id
    @backdrop_id ||= "hero-#{eyebrow.parameterize}"
  end
end
