class Page::Dashboard::RecommendedTrialsComponent < ApplicationComponent
  def initialize(trials:)
    @trials = trials
  end

  def get_icon_for_criteria(label)
    case label
    when "microscope"
      "microscope"
    else
      "check_circle"
    end
  end
end
