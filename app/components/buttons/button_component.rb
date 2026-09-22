# Renders a link that looks like a button. Forms::SubmitComponent renders an
# input that looks the same, because both read Buttons::ButtonStyles.
class Buttons::ButtonComponent < ApplicationComponent
  attr_reader :path, :text, :icon, :color, :icon_position

  def initialize(path:, text:, color: nil, icon: nil, icon_position: "left")
    @path = path
    @text = text
    @icon = icon
    @color = color
    @icon_position = icon_position
  end

  def color_styles
    Buttons::ButtonStyles.classes(color)
  end
end
