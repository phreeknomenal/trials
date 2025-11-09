class Page::StudyCardComponent < ApplicationComponent
  attr_reader :study

  def initialize(study:)
    @study = study
  end

  def status_badge_class
    case study[:status]
    when "Recruiting"
      "bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-300"
    when "Active, not recruiting"
      "bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-300"
    when "Completed"
      "bg-zinc-100 text-zinc-800 dark:bg-zinc-700 dark:text-zinc-300"
    when "Not yet recruiting"
      "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-300"
    when "Enrolling by invitation"
      "bg-purple-100 text-purple-800 dark:bg-purple-900/20 dark:text-purple-300"
    when "Suspended", "Terminated", "Withdrawn"
      "bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-300"
    else
      "bg-zinc-100 text-zinc-800 dark:bg-zinc-700 dark:text-zinc-300"
    end
  end
end
