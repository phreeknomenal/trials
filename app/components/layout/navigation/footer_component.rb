class Layout::Navigation::FooterComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="grid grid-cols-5 border-y border-zinc-200 dark:border-zinc-700 px-5 lg:px-36 py-10 gap-5">
      <div class="col-span-5 lg:col-span-3 grid grid-cols-3 order-2 lg:order-1">
        <%= render Layout::Navigation::Menu::FooterLinkComponent.new %>
      </div>
      <div class="col-span-5 lg:col-span-2 order-2 lg:order-1">
        <h2 class="text-6xl font-bold text-zinc-900 dark:text-zinc-300">Lumen</h2>
        <p class="text-zinc-500 dark:text-zinc-400">Find clinical trials that match your journey</p>

        <div class="mt-5">
          <div class="w-1/2 flex gap-2">
            <input type="email" placeholder="Enter your email" class="flex-1 px-4 py-2 rounded-lg border border-zinc-200 dark:border-zinc-700 focus:outline-none focus:border-zinc-200 dark:focus:border-zinc-700 text-zinc-600 dark:text-zinc-600 transition-all duration-300">
            <button class="bg-lavender-600 text-white px-6 py-2 rounded-lg hover:bg-zinc-800 dark:hover:bg-zinc-400 transition-all duration-300 font-medium">
              Subscribe
            </button>
          </div>
          <p class="text-xs text-zinc-500 mt-2">Subscribe to our newsletter for weekly recipe updates</p>
        </div>
      </div>
    </div>

    <div class="flex mx-5 lg:mx-36 py-5 gap-5 items-center justify-center">
      <div class="flex justify-center items-center text-zinc-900 dark:text-zinc-700">
        &copy; 2025 - Lumen - Made with <%= render Utilities::IconComponent.new("heart_full", size: 6) %> and <%= render Utilities::IconComponent.new("mug_hot", size: 6) %> in Birmingham, AL.
      </div>
    </div>
  ERB
end
