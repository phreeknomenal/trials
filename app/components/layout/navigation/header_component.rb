class Layout::Navigation::HeaderComponent < ApplicationComponent
  erb_template <<-ERB
    <header>
      <div class="w-[80%] mx-auto flex items-center justify-between py-4">
        <div>
          <h1 class="text-2xl font-bold tracking-tight">Clinical Trial Finder</h1>
        </div>
        <%= render Layout::Navigation::Menu::HeaderMenuComponent.new %>
      </div>
    </header>
  ERB
end
