class Page::Cards::QuoteComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="w-full h-full flex flex-col gap-x-4 border border-zinc-200 rounded-lg p-6 space-y-3">
      <div class="w-auto h-4 flex gap-1 mb-5">
        <%= render Utilities::IconComponent.new("star", size: 6) %>
        <%= render Utilities::IconComponent.new("star", size: 6) %>
        <%= render Utilities::IconComponent.new("star", size: 6) %>
        <%= render Utilities::IconComponent.new("star", size: 6) %>
        <%= render Utilities::IconComponent.new("star", size: 6) %>
      </div>
      <div class="mb-8">
        <%= render Typography::ParagraphComponent.new(text: quote) %>
      </div>
      <div class="mt-auto">
        <div class="flex items-center gap-2">
          <div class="w-10 h-10">
            <%= render Utilities::AvatarComponent.new(profile) %>
          </div>
          <div class="flex flex-col">
            <h3 class="text-base font-bold"><%= profile.full_name %></h3>
            <p class="text-sm font-body text-zinc-600">Cancer Survivor, research participant</p>
          </div>
        </div>
      </div>
    </div>
  ERB

  attr_reader :quote, :author, :profile

  def initialize(quote:, profile:)
    @quote = quote
    @profile = profile
  end
end
