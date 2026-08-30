class Page::Cards::QuoteComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="w-full h-full flex flex-col gap-x-4 border border-zinc-300 dark:border-zinc-700 rounded-lg p-6 space-y-3">
      <div class="w-auto h-4 flex gap-1 mb-5 text-lavender-600">
        <%= render Utilities::IconComponent.new("star_solid", size: 6) %>
        <%= render Utilities::IconComponent.new("star_solid", size: 6) %>
        <%= render Utilities::IconComponent.new("star_solid", size: 6) %>
        <%= render Utilities::IconComponent.new("star_solid", size: 6) %>
        <%= render Utilities::IconComponent.new("star_solid", size: 6) %>
      </div>
      <div class="mb-8">
        <%= render Typography::ParagraphComponent.new(text: testimonial.quote) %>
      </div>
      <div class="mt-auto">
        <div class="flex items-center gap-2">
          <div class="w-10 h-10">
            <%= render Utilities::AvatarComponent.new(avatar: testimonial.avatar, initials: testimonial.initials) %>
          </div>
          <div class="flex flex-col">
            <h3 class="text-base font-bold text-zinc-900 dark:text-zinc-300"><%= testimonial.author_name %></h3>
            <% if testimonial.author_role.present? %>
              <p class="text-sm font-body text-zinc-600 dark:text-zinc-400"><%= testimonial.author_role %></p>
            <% end %>
          </div>
        </div>
      </div>
    </div>
  ERB

  attr_reader :testimonial

  def initialize(testimonial:)
    @testimonial = testimonial
  end
end
