class Page::Cards::QuoteComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="w-full h-full flex flex-col gap-x-4 border border-line-2 dark:border-line-on-dark rounded-lg p-6 space-y-3">
      <div class="w-auto h-4 flex gap-1 mb-5 text-sky-600">
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
            <%= render Utilities::AvatarComponent.new(avatar: testimonial.avatar, initials: testimonial.initials, size: 40) %>
          </div>
          <div class="flex flex-col">
            <h3 class="text-base font-bold text-ink dark:text-ink-2-on-dark"><%= testimonial.author_name %></h3>
            <% if testimonial.author_role.present? %>
              <p class="text-sm font-body text-ink-3 dark:text-ink-3-on-dark"><%= testimonial.author_role %></p>
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
