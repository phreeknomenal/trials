class Page::Cards::StudyCardComponent < ApplicationComponent
  attr_reader :study

  def initialize(study:)
    @study = study
  end
end
