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
end
