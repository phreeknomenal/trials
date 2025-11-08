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
    case color
    when "coral"
      "border border-coral-600 text-white bg-coral-600 hover:border-lavender-600 hover:bg-lavender-600 transition-all"
    when "lavender"
      "border border-lavender-600 text-white bg-lavender-600 hover:border-coral-600 hover:bg-coral-600 transition-all"
    when "white"
      "border border-zinc-200 text-zinc-600 bg-white hover:border-coral-600 hover:text-white hover:bg-coral-600 transition-all"
    when "clear"
      "border border-transparent text-zinc-600 dark:text-zinc-300 bg-transparent hover:border-coral-600 hover:text-white hover:bg-coral-600 transition-all"
    when "clear_zinc"
      "border border-zinc-600 dark:border-zinc-300 text-zinc-600 dark:text-zinc-300 bg-transparent hover:border-coral-600 hover:text-white hover:bg-coral-600 transition-all"
    else
      "border border-zinc-600 dark:border-zinc-300 text-zinc-900 dark:text-zinc-300 bg-transparent hover:border-coral-600 hover:text-white hover:bg-coral-600 transition-all"
    end
  end
end
