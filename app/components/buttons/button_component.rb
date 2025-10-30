class Buttons::ButtonComponent < ApplicationComponent
  attr_reader :path, :text, :icon, :color

  def initialize(path:, text:, color: nil, icon: nil)
    @path = path
    @text = text
    @icon = icon
    @color = color
  end

  def color_styles
    case color
    when "coral"
      "border border-coral-600 text-white  bg-coral-600"
    when "lavender"
      "border border-lavender-600 text-white  bg-lavender-600"
    when "white"
      "border border-zinc-200 text-zinc-600 bg-white"
    else
      "border border-zinc-200 text-zinc-600 bg-transparent"
    end
  end
end
