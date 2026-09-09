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
    super(status: status, text: text)
  end

  def badge_classes
    base_classes = "inline-block rounded-full uppercase"
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
      "text-sky-100 bg-navy-600 font-bold"
    when :recruiting
      "bg-good/10 text-good dark:text-good-on-dark font-bold"
    when :active
      "bg-good/10 text-good dark:text-good-on-dark font-bold"
    when :completed
      "bg-ink-4/15 text-ink-2 dark:text-ink-2-on-dark font-bold"
    when :suspended, :terminated, :withdrawn
      "bg-crit/10 text-crit dark:text-crit-on-dark font-bold"
    when :not_yet_recruiting
      "bg-warn/10 text-warn dark:text-warn-on-dark font-bold"
    when :tag
      "bg-surface-2 text-ink-2 dark:bg-surface-2-on-dark dark:text-ink-2-on-dark"
    else
      "bg-sky-100 text-sky-800 dark:bg-navy-900/20 dark:text-sky-300"
    end
  end

  def size_classes
    case size
    when :sm
      "text-xs px-2 py-1"
    when :md
      "text-sm px-3 py-1"
    when :lg
      "text-base px-3 py-1.5"
    else
      "text-sm px-3 py-1"
    end
  end
end
