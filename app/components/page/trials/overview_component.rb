class Page::Trials::OverviewComponent < ApplicationComponent
  attr_reader :study, :nct_id

  def initialize(study: nil, nct_id: nil)
    @study = study
    @nct_id = nct_id
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

  def readable_summary
    ReadableStudySummary.find_by(nct_id: nct_id)
  end

  def source_present?
    summary.present? || detailed_description.present?
  end
end
