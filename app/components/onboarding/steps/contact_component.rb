class Onboarding::Steps::ContactComponent < Onboarding::Steps::BaseComponent
  CONTACT_LABELS = {
    Profile::EMAIL => "Email",
    Profile::SMS => "Text message",
    Profile::IN_APP => "In the app"
  }.freeze

  def contact_options
    Profile::CONTACT_PREFERENCE_OPTIONS.map { |option| [CONTACT_LABELS.fetch(option) { option_label(option) }, option] }
  end
end
