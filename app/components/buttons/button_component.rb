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
    when "primary"
      "border border-navy-600 text-white bg-navy-600 hover:border-navy-700 hover:bg-navy-700 transition-all"
    when "white"
      "border border-zinc-200 text-zinc-600 bg-white hover:border-navy-700 hover:text-white hover:bg-navy-700 transition-all"
    when "clear"
      "border border-transparent text-zinc-600 dark:text-zinc-300 bg-transparent hover:border-navy-700 hover:text-white hover:bg-navy-700 transition-all"
    when "clear_zinc"
      "border border-zinc-600 dark:border-zinc-300 text-zinc-600 dark:text-zinc-300 bg-transparent hover:border-navy-700 hover:text-white hover:bg-navy-700 transition-all"
    else
      "border border-zinc-600 dark:border-zinc-300 text-zinc-900 dark:text-zinc-300 bg-transparent hover:border-navy-700 hover:text-white hover:bg-navy-700 transition-all"
    end
  end
end
