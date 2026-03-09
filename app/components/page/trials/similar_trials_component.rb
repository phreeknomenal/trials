# frozen_string_literal: true

class Page::Trials::SimilarTrialsComponent < ApplicationComponent
  def initialize(trials:)
    @trials = trials
  end
end
