# The one place the page's measure is decided.
#
# Every page used to pick its own. At a 1713px viewport the landing page, search,
# the dashboard, the profile and saved studies all started their content at 96px
# (`px-5 lg:px-24`, full bleed); About, the FAQ and the privacy policy started at
# 377px (`max-w-5xl`, centred); and the header and footer started at 313px
# (`max-w-6xl`, centred). Nothing lined up with anything, and the chrome lined up
# with neither group, so the wordmark sat 217px inboard of the page under it.
#
# On the design canvas the problem does not exist: every board is a 1440 frame
# where the header, the footer and every section share the same gutters, so they
# are flush by construction. The app lost that because each page chose a
# container as it was built and the chrome chose a third.
#
# Same failure as the button and field kits before PR 2, and as the header's
# hand-rolled Login: a value that should have been stated once, written
# independently in nine places, drifting with nothing to report it.
#
# ---
#
# This was first written as a centred `max-w-6xl` cap, which was the wrong call
# and is worth recording as one. 1152px centred leaves 281px of empty page on
# each side of a 1713px display, a third of the screen, and the pages that had
# been full bleed visibly lost width to match the chrome. The chrome was the
# thing that was wrong, so the chrome is what moved.
#
# The gutters are what the boards actually specify: a fixed inset from the edge,
# not a centred column. 96px here against the boards' 130px, because 96 is what
# seven of the app's pages already used and matching them is the point. Content
# grows with the display, which is right for a results grid and harmless for
# prose, because every prose column sets its own `max-w-3xl` inside this.
module Layout::PageWidth
  # The measure itself. Put this on the element that holds the content.
  #
  # No max-width. If this ever needs a ceiling for very wide displays it belongs
  # here and nowhere else, which is the whole point of the file.
  CONTAINER = "w-full px-5 lg:px-24"

  # A full-bleed band keeps its own background and border running the whole
  # width, and puts CONTAINER on a wrapper inside it. A section that tints or
  # rules the page must not carry the gutters itself, or the rule inherits the
  # inset and stops short of the edge.
  #
  #   <section class="border-b border-line bg-paper">
  #     <div class="#{CONTAINER} py-16">...</div>
  #   </section>
  #
  # Admin is deliberately not on this. It renders wide read-only tables under its
  # own layout and its own nav, on a tighter inset that suits a dense table.
  def self.container(extra = nil)
    [CONTAINER, extra].compact.join(" ")
  end
end
