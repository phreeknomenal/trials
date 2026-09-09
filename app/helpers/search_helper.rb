module SearchHelper
  def status_badge_class(status)
    case status
    when "Recruiting"
      "bg-good/10 text-good dark:bg-good-on-dark/20 dark:text-good-on-dark"
    when "Active, not recruiting"
      "bg-info/10 text-info dark:bg-info-on-dark/20 dark:text-info-on-dark"
    when "Completed"
      "bg-surface-2 text-ink-2 dark:bg-surface-2-on-dark dark:text-ink-2-on-dark"
    when "Not yet recruiting"
      "bg-warn/10 text-warn dark:bg-warn-on-dark/20 dark:text-warn-on-dark"
    when "Enrolling by invitation"
      "bg-info/10 text-info dark:bg-info-on-dark/20 dark:text-info-on-dark"
    when "Suspended", "Terminated", "Withdrawn"
      "bg-crit/10 text-crit dark:bg-crit-on-dark/20 dark:text-crit-on-dark"
    else
      "bg-surface-2 text-ink-2 dark:bg-surface-2-on-dark dark:text-ink-2-on-dark"
    end
  end
end
