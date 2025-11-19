class Page::Trials::KeyDetailsComponent < ApplicationComponent
  def initialize(study:)
    @study = study
  end

  def display_text
    if status.present?
      status&.gsub("_", " ")&.titleize
    else
      text
    end
  end
end
