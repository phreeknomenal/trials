class Onboarding::Steps::LogisticsComponent < Onboarding::Steps::BaseComponent
  def travel_options
    Profile::TRAVEL_MILES_OPTIONS.map { |miles| ["Up to #{miles} miles", miles] } +
      [[DECLINE_LABELS.fetch(Profile::NO_PREFERENCE), Profile::NO_TRAVEL_PREFERENCE]]
  end

  def remote_visit_options
    Profile::REMOTE_VISIT_PREFERENCE_OPTIONS.map { |option| [option_label(option), option] }
  end
end
