class Layout::Navigation::FooterComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="grid grid-cols-5 border-y border-line dark:border-line-on-dark px-5 lg:px-36 py-10 gap-5">
      <div class="col-span-5 lg:col-span-3 grid grid-cols-3 order-2 lg:order-1">
        <%= render Layout::Navigation::Menu::FooterLinkComponent.new %>
      </div>
      <div class="col-span-5 lg:col-span-2 order-2 lg:order-1">
        <div class="flex items-center gap-3">
          <%= render Utilities::MarkComponent.new(height: 12) %>
          <h2 class="font-primary text-6xl font-extrabold tracking-tight text-ink dark:text-ink-2-on-dark">Dira<span class="font-light text-ink-3 dark:text-ink-3-on-dark"> Health</span></h2>
        </div>
        <p class="text-ink-3 dark:text-ink-3-on-dark">Find clinical trials that match your journey</p>

        <div class="mt-5">
          <div class="w-1/2 flex gap-2">
            <input type="email" placeholder="Enter your email" class="flex-1 px-4 py-2 rounded-lg border border-line dark:border-line-on-dark focus:outline-none focus:border-line dark:focus:border-line-on-dark text-ink-3 dark:text-ink-4-on-dark transition-all duration-300">
            <button class="bg-navy-600 text-white px-6 py-2 rounded-lg hover:bg-navy-700 dark:hover:bg-navy-500 transition-colors duration-200 font-semibold focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-500">
              Subscribe
            </button>
          </div>
          <p class="text-xs text-ink-3 mt-2">Subscribe for new studies that match your profile</p>
        </div>
      </div>
    </div>

    <div class="flex mx-5 lg:mx-36 py-5 gap-5 items-center justify-center">
      <div class="flex justify-center items-center text-ink dark:text-ink-4-on-dark">
        &copy; 2026 - Dira Health - Made with <%= render Utilities::IconComponent.new("heart_full", size: 6) %> and <%= render Utilities::IconComponent.new("mug_hot", size: 6) %> in Birmingham, AL.
      </div>
    </div>
  ERB
end
