class Layout::Navigation::FooterComponent < ApplicationComponent
  # The email capture that used to sit here is gone. It was an <input> and a
  # Subscribe <button> with no <form> around them and no action to submit to, so
  # clicking it did nothing at all: no request, no error, no feedback. The app
  # also has no SMTP configured in any environment, so there was nothing it
  # could have done even if it had submitted.
  #
  # It belongs with the email alerts feature, which is blocked on SMTP, and it
  # comes back when that ships and works. A subscribe box that silently discards
  # an address is worse than no subscribe box, because someone who types their
  # address into it believes they will hear from us.
  erb_template <<-ERB
    <footer class="border-y border-line dark:border-line-on-dark px-5 lg:px-36 py-10">
      <div class="grid gap-10 lg:grid-cols-5">
        <div class="lg:col-span-2 flex flex-col gap-3">
          <div class="flex items-center gap-3">
            <%= render Utilities::MarkComponent.new(height: 12) %>
            <h2 class="font-primary text-6xl font-extrabold tracking-tight text-ink dark:text-ink-2-on-dark">Dira<span class="font-light text-ink-3 dark:text-ink-3-on-dark"> Health</span></h2>
          </div>
          <p class="text-ink-3 dark:text-ink-3-on-dark">Find clinical trials that match your journey</p>
          <p class="text-sm leading-relaxed text-ink-3 dark:text-ink-3-on-dark max-w-sm">
            Studies come from ClinicalTrials.gov, the public registry. We are not a medical provider,
            and nothing here is medical advice.
          </p>
        </div>

        <nav class="lg:col-span-3 grid grid-cols-2 sm:grid-cols-3 gap-8" aria-label="Footer">
          <%= render Layout::Navigation::Menu::FooterLinkComponent.new %>
        </nav>
      </div>
    </footer>

    <div class="flex mx-5 lg:mx-36 py-5 gap-5 items-center justify-center">
      <div class="flex justify-center items-center text-ink dark:text-ink-4-on-dark">
        &copy; 2026 - Dira Health - Made with <%= render Utilities::IconComponent.new("heart_full", size: 6) %> and <%= render Utilities::IconComponent.new("mug_hot", size: 6) %> in Birmingham, AL.
      </div>
    </div>
  ERB
end
