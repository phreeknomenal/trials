class Page::Trials::OverviewComponent < ApplicationComponent
  attr_reader :study

  def initialize(study: nil)
    @study = study
  end

  def summary
    @study[:summary]
  end

  def detailed_description
    @study[:detailed_description]
  end

  def conditions
    @study[:conditions]
  end
end
