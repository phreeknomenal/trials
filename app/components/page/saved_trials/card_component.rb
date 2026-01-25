class Page::SavedTrials::CardComponent < ApplicationComponent
  attr_reader :saved_trial

  def initialize(saved_trial:)
    @saved_trial = saved_trial
  end
end
