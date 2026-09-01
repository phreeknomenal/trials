class Onboarding::Steps::LogisticsComponent < Onboarding::Steps::BaseComponent
  def travel_options
    Profile::TRAVEL_MILES_OPTIONS.map { |miles| ["Up to #{miles} miles", miles] }
  end

  def remote_visit_options
    Profile::REMOTE_VISIT_PREFERENCE_OPTIONS.map { |option| [option.titleize, option] }
  end
end
