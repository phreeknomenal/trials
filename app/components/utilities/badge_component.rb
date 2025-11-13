class Utilities::BadgeComponent < ApplicationComponent
  erb_template <<~ERB
    <span class="<%= badge_classes %>">
      <%= display_text %>
    </span>
  ERB

  attr_reader :text, :variant, :size, :status

  def initialize(text: nil, variant: nil, size: :md, status: nil)
    @text = text
    @status = status
    @variant = variant
    @size = size
  end

  def display_text
    if status.present?
      status&.gsub("_", " ")&.titleize
    else
      text
    end
  end

  def badge_classes
    base_classes = "inline-block rounded-full"
    "#{base_classes} #{variant_classes} #{size_classes}"
  end

  def computed_variant
    return variant if variant.present?
    return :default unless status.present?

    normalized_status = status.upcase.gsub(/[,_\s]+/, "_")

    case normalized_status
    when /RECRUITING/
      normalized_status.include?("NOT") ? :not_yet_recruiting : :recruiting
    when /ACTIVE/
      :active
    when "COMPLETED"
      :completed
    when "SUSPENDED", "TERMINATED", "WITHDRAWN"
      :suspended
    else
      :default
    end
  end

  private

  def variant_classes
    case computed_variant
    when :nct_id
      "text-lavender-100 bg-lavender-600 font-bold"
    when :recruiting
      "bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-300 font-bold"
    when :active
      "bg-lime-100 text-lime-800 dark:bg-lime-900/20 dark:text-lime-300 font-bold"
    when :completed
      "bg-teal-100 text-teal-800 dark:bg-teal-900/20 dark:text-teal-300 font-bold"
    when :suspended, :terminated, :withdrawn
      "bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-300 font-bold font-bold"
    when :not_yet_recruiting
      "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-300 font-bold"
    when :tag
      "bg-zinc-200 text-zinc-800 dark:bg-zinc-700 dark:text-zinc-300"
    else
      "bg-lavender-100 text-lavender-800 dark:bg-lavender-900/20 dark:text-lavender-300"
    end
  end

  def size_classes
    case size
    when :sm
      "text-sm px-2 py-1"
    when :md
      "text-base px-3 py-1"
    when :lg
      "text-xl px-3 py-1.5"
    else
      "text-base px-3 py-1"
    end
  end
end
