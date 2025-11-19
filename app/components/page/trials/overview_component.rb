class Page::Trials::OverviewComponent < ApplicationComponent
  def initialize(summary:, detailed_description: nil)
    @summary = summary
    @detailed_description = detailed_description
  end
end
