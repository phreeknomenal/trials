class Page::Trials::EligibilityChecklistComponent < ApplicationComponent
  def initialize(checklist_items:)
    @checklist_items = checklist_items
  end

  def status_badge_class(status)
    case status
    when "met"
      "bg-good/10 text-good dark:text-good-on-dark border border-good/30"
    when "not_met"
      "bg-crit/10 text-crit dark:text-crit-on-dark border border-crit/30"
    when "warning"
      "bg-warn/10 text-warn dark:text-warn-on-dark border border-warn/30"
    when "unknown"
      "bg-surface-2 dark:bg-surface-2-on-dark text-ink-3 dark:text-ink-3-on-dark border border-line dark:border-line-on-dark"
    else
      "bg-info/10 text-info dark:text-info-on-dark border border-info/30"
    end
  end

  def status_icon_color(status)
    case status
    when "met"
      "text-good dark:text-good-on-dark"
    when "not_met"
      "text-crit dark:text-crit-on-dark"
    when "warning"
      "text-warn dark:text-warn-on-dark"
    when "unknown"
      "text-ink-3 dark:text-ink-3-on-dark"
    else
      "text-info dark:text-info-on-dark"
    end
  end

  def status_label(status)
    case status
    when "met"
      "Eligible"
    when "not_met"
      "Not Eligible"
    when "warning"
      "Review"
    when "unknown"
      "Unknown"
    else
      "Note"
    end
  end
end
