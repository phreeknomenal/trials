class Page::Trials::EligibilityChecklistComponent < ApplicationComponent
  def initialize(checklist_items:)
    @checklist_items = checklist_items
  end

  def status_badge_class(status)
    case status
    when "met"
      "bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 border border-green-200 dark:border-green-800"
    when "not_met"
      "bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300 border border-red-200 dark:border-red-800"
    when "warning"
      "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-800"
    when "unknown"
      "bg-gray-100 dark:bg-gray-700/30 text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-gray-700"
    else
      "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 border border-blue-200 dark:border-blue-800"
    end
  end

  def status_icon_color(status)
    case status
    when "met"
      "text-green-600 dark:text-green-400"
    when "not_met"
      "text-red-600 dark:text-red-400"
    when "warning"
      "text-amber-600 dark:text-amber-400"
    when "unknown"
      "text-gray-600 dark:text-gray-400"
    else
      "text-blue-600 dark:text-blue-400"
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
