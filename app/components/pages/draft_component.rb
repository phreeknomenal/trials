# A passage that has not been written yet, shown as a marked gap.
#
# The alternative was to leave the design board's bracketed text in place,
# rendered as ordinary prose. On a health site that is the worse option twice
# over: a visitor reads "[PLACEHOLDER. State how this is actually paid for.]"
# as either broken or as an answer, and whoever ships next has no list of what
# is still outstanding.
#
# So an unwritten passage looks unwritten, says what it is waiting on, and is
# countable. `spec/components/pages/draft_component_spec.rb` and the page
# request specs assert the count, which means removing the last one is a
# deliberate act rather than something nobody noticed.
class Pages::DraftComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="rounded-card border border-dashed border-warn/60 dark:border-warn-on-dark/60
                bg-warn/5 dark:bg-warn-on-dark/10 p-4 flex gap-3 items-start"
         data-draft-section="<%= label.parameterize %>">
      <span class="text-warn dark:text-warn-on-dark shrink-0 mt-0.5">
        <%= render Utilities::IconComponent.new("exclamation_triangle", size: 5) %>
      </span>
      <div class="flex flex-col gap-1">
        <p class="text-sm font-bold text-warn dark:text-warn-on-dark">
          Not written yet: <%= label %>
        </p>
        <p class="text-sm leading-relaxed text-ink-2 dark:text-ink-2-on-dark"><%= waiting_on %></p>
      </div>
    </div>
  ERB

  attr_reader :label, :waiting_on

  def initialize(label:, waiting_on:)
    @label = label
    @waiting_on = waiting_on
  end
end
