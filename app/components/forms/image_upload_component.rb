class Forms::ImageUploadComponent < ApplicationComponent
  attr_reader :form, :attribute

  def initialize(form:, attribute:)
    @form = form
    @attribute = attribute
  end
end
