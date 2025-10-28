class Utilities::AvatarComponent < ApplicationComponent
  erb_template <<~ERB
    <% if profile.avatar.present? %>
      <%= image_tag profile.avatar, class: "w-full h-full object-cover rounded-full" %>
    <% else %>
      <div class="flex items-center justify-center w-full h-full rounded-full text-white font-medium" style="background-color: <%= background_color %>">
        <%= initials %>
      </div>
    <% end %>
  ERB

  attr_reader :profile

  def initialize(profile)
    @profile = profile
  end

  def background_color
    avatar_colors = [ "#534d6e", "#464d66", "#425b5e", "#65705b", "#3c6660", "#355c73", "#6c456e", "#7d4a62", "#0e0e0f" ]
    seed = (initials[0].ord + initials[1].ord) % avatar_colors.length
    avatar_colors[seed] || "#000000"
  end

  def initials
    (profile.first_name&.first&.upcase.to_s + profile.last_name&.first&.upcase.to_s).presence || "UU"
  end
end
