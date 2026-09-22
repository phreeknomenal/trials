class Page::Cards::StudyCardComponent < ApplicationComponent
  attr_reader :study

  def initialize(study:)
    @study = study
  end

  def detail_path
    search_path(study[:nct_id])
  end
end
