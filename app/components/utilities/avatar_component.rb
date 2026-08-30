# Presentational only. Takes an avatar attachment and initials rather than a
# model, so any record can use it -- Profile and Testimonial both do.
class Utilities::AvatarComponent < ApplicationComponent
  erb_template <<~ERB
    <% if avatar.present? %>
      <%= image_tag avatar, class: "w-full h-full object-cover rounded-full" %>
    <% else %>
      <div class="flex items-center justify-center w-full h-full rounded-full text-white font-medium" style="background-color: <%= background_color %>">
        <%= display_initials %>
      </div>
    <% end %>
  ERB

  AVATAR_COLORS = [
    "#534d6e", "#464d66", "#425b5e", "#65705b", "#3c6660",
    "#355c73", "#6c456e", "#7d4a62", "#0e0e0f"
  ].freeze

  FALLBACK_INITIALS = "UU".freeze

  attr_reader :avatar, :initials

  def initialize(avatar:, initials:)
    @avatar = avatar
    @initials = initials.to_s
  end

  def display_initials
    initials.presence || FALLBACK_INITIALS
  end

  # Sums every character rather than indexing two fixed positions. The previous
  # implementation did initials[0].ord + initials[1].ord, which raised
  # NoMethodError on nil for any single-character initials -- a profile with a
  # first name and no last name, or a one-word testimonial author.
  def background_color
    seed = display_initials.each_char.sum(&:ord)
    AVATAR_COLORS[seed % AVATAR_COLORS.length]
  end
end
