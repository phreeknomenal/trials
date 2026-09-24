# The one place the page's measure is decided.
#
# Every page used to pick its own. At a 1720px viewport the landing page, search,
# the dashboard, the profile and saved studies all started their content at 96px
# (`px-5 lg:px-24`, full bleed); About, the FAQ and the privacy policy started at
# 377px (`max-w-5xl`, centred); and the header and footer started at 313px
# (`max-w-6xl`, centred). Nothing lined up with anything, and the chrome lined up
# with neither group, so the wordmark sat 217px inboard of the page under it.
#
# On the design canvas the problem does not exist: every board is a 1440 frame
# where the header, the footer and every section share the same 130px gutters, so
# they are flush by construction. The app lost that because each page chose a
# container as it was built and the chrome chose a third.
#
# Same failure as the button and field kits before PR 2: a value that should have
# been stated once, written independently in nine places, drifting with nothing
# to report it.
#
# 1152px is `max-w-6xl`, the standard step nearest the board's 1180px of content.
# A named step is worth 28px of imprecision: the next person reaching for a width
# will recognise `max-w-6xl` and will not recognise `max-w-[1180px]`.
module Layout::PageWidth
  # The measure itself. Put this on the element that holds the content.
  CONTAINER = "mx-auto w-full max-w-6xl px-5 lg:px-8"

  # A full-bleed band keeps its own background and border running the whole
  # width, and puts CONTAINER on a wrapper inside it. A section that tints or
  # rules the page must not be capped, or the rule stops at 1152px and the band
  # reads as a floating card.
  #
  #   <section class="border-b border-line bg-paper">
  #     <div class="#{CONTAINER} py-16">...</div>
  #   </section>
  #
  # Admin is deliberately not on this. It renders wide read-only tables under its
  # own layout and its own nav, and capping those at 1152px would force a
  # horizontal scroll on the one surface where seeing every column at once is the
  # point.
  def self.container(extra = nil)
    [CONTAINER, extra].compact.join(" ")
  end
end
