class Layout::Navigation::FooterComponent < ApplicationComponent
  # Restyled onto the landing board's footer treatment. The structure was already
  # right: brand block left, link columns right, a rule, then the copyright
  # centred under it. What was wrong was the scale.
  #
  # The wordmark was `text-6xl`, 60px, against the board's 34px. A footer
  # wordmark at 60px is larger than every heading on every page in the app, which
  # made the loudest thing on a study detail page the word "Dira" at the bottom
  # of it. Column headings were `text-xl` against the board's 15px, so a footer
  # heading outweighed the links under it by half again.
  #
  # The email capture that used to sit here is gone. It was an <input> and a
  # Subscribe <button> with no <form> around them and no action to submit to, so
  # clicking it did nothing at all: no request, no error, no feedback. The app
  # also has no SMTP configured in any environment, so there was nothing it
  # could have done even if it had submitted.
  #
  # The board does draw it, so its absence is a decision rather than an
  # oversight: it belongs with the email alerts feature, which is blocked on
  # SMTP, and it comes back when that ships and works. A subscribe box that
  # silently discards an address is worse than no subscribe box, because someone
  # who types their address into it believes they will hear from us.
  erb_template <<-ERB
    <footer class="border-t border-line dark:border-line-on-dark">
      <div class="<%= Layout::PageWidth::CONTAINER %> py-14 grid gap-12 lg:grid-cols-5">
        <div class="lg:col-span-2 flex flex-col gap-4">
          <div class="flex items-center gap-3">
            <%= render Utilities::MarkComponent.new(height: 10) %>
            <span class="font-primary text-4xl tracking-tight">
              <span class="font-extrabold text-ink dark:text-ink-2-on-dark">Dira</span><span class="font-light text-ink-3 dark:text-ink-3-on-dark"> Health</span>
            </span>
          </div>
          <p class="text-[15px] text-ink-3 dark:text-ink-3-on-dark">Find clinical trials that match your journey</p>
          <p class="text-sm leading-relaxed text-ink-3 dark:text-ink-3-on-dark max-w-sm">
            Studies come from ClinicalTrials.gov, the public registry. We are not a medical provider,
            and nothing here is medical advice.
          </p>
        </div>

        <nav class="lg:col-span-3 grid grid-cols-2 sm:grid-cols-3 gap-8" aria-label="Footer">
          <%= render Layout::Navigation::Menu::FooterLinkComponent.new %>
        </nav>
      </div>

      <div class="border-t border-line dark:border-line-on-dark">
        <div class="<%= Layout::PageWidth::CONTAINER %> py-6 flex justify-center">
          <span class="text-sm text-ink-3 dark:text-ink-3-on-dark flex items-center gap-1.5">
            &copy; 2026 Dira Health. Made with
            <%= render Utilities::IconComponent.new("heart_full", size: 4) %>
            and
            <%= render Utilities::IconComponent.new("mug_hot", size: 4) %>
            in Birmingham, AL.
          </span>
        </div>
      </div>
    </footer>
  ERB
end
