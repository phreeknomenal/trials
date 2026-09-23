# A single avatar picker: the photo on the account, or the one just chosen, with
# a button to change it.
#
# What it replaced declared a multi-file preview system against a Stimulus
# controller that did not exist, so choosing a file did nothing visible. It also
# set multiple: true on an input bound to has_one_attached, where only one file
# can survive and which one is not defined.
class Forms::ImageUploadComponent < ApplicationComponent
  attr_reader :form, :attribute, :current, :initials

  def initialize(form:, attribute:, current: nil, initials: nil)
    @form = form
    @attribute = attribute
    @current = current
    @initials = initials
  end

  def current_image? = current.respond_to?(:attached?) && current.attached?

  def button_label = current_image? ? "Change photo" : "Add a photo"
end
