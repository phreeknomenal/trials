# Presentational only. Takes an avatar attachment and initials rather than a
# model, so any record can use it -- Profile and Testimonial both do.
class Utilities::AvatarComponent < ApplicationComponent
  erb_template <<-ERB
    <% if image.present? %>
      <%= image_tag image,
            class: "w-full h-full object-cover rounded-full",
            width: size, height: size, loading: "lazy", alt: "" %>
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

  # Display size in CSS pixels. The wrapper still governs layout; this is what
  # the variant is cut to and what the width and height attributes report, so
  # the box is reserved before the image arrives.
  DEFAULT_SIZE = 40

  # Cut at twice the display size so the image is not soft on a retina screen.
  RETINA_SCALE = 2

  attr_reader :avatar, :initials, :size

  def initialize(avatar:, initials:, size: DEFAULT_SIZE)
    @avatar = avatar
    @initials = initials.to_s
    @size = size
  end

  # Uploads were being served at full size and scaled down by CSS, so a phone
  # photo of several megabytes was downloaded to fill a 40px circle.
  #
  # Not .processed: that would generate the variant during the request. The
  # representation URL processes on first access instead, so the page is not
  # held up by an image nobody has asked for yet.
  def image
    return if avatar.blank?
    return avatar unless avatar.variable?

    avatar.variant(resize_to_fill: [variant_size, variant_size])
  end

  def variant_size
    size * RETINA_SCALE
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
