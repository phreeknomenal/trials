class Page::Trials::OverviewComponent < ApplicationComponent
  attr_reader :study, :nct_id

  # Both are required. nct_id previously defaulted to nil, which let
  # search/show.html.erb render without it and blow up downstream in
  # generate_readable_summary_my_trial_path(nil) rather than here.
  def initialize(study:, nct_id:)
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
