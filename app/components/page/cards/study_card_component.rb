class Page::Cards::StudyCardComponent < ApplicationComponent
  attr_reader :study, :base_path

  def initialize(study:, base_path: :search)
    @study = study
    @base_path = base_path
  end

  def detail_path
    if base_path == :my_trials
      my_trial_path(study[:nct_id])
    else
      search_path(study[:nct_id])
    end
  end

  def match_score_class(match_level)
    case match_level
    when "excellent"
      "bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-200 border border-green-200 dark:border-green-800"
    when "good"
      "bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-200 border border-blue-200 dark:border-blue-800"
    when "fair"
      "bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-200 border border-yellow-200 dark:border-yellow-800"
    else
      "bg-gray-100 dark:bg-gray-900/30 text-gray-800 dark:text-gray-200 border border-gray-200 dark:border-gray-800"
    end
  end
end
