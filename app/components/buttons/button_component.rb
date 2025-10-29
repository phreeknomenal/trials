class Buttons::ButtonComponent < ApplicationComponent
  attr_reader :path, :text, :icon, :color

  def initialize(path:, text:, color: "lime", icon: nil)
    @path = path
    @text = text
    @icon = icon
    @color = color
  end
end
