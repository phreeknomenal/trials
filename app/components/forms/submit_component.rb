# Renders a form submit that looks exactly like Buttons::ButtonComponent, because
# both now read Buttons::ButtonStyles. See that file for what they used to do
# instead.
class Forms::SubmitComponent < ApplicationComponent
  erb_template <<-ERB
    <%= form.submit text, class: style_class, **options %>
  ERB

  attr_reader :form, :text, :style, :options

  def initialize(form:, text: "Submit", style: :primary, options: {})
    @form = form
    @text = text
    @style = style
    @options = options
  end

  # :disabled was a style in its own right, which meant a button could look
  # disabled while being perfectly clickable. Disabled is a state of the control
  # now, handled by the disabled: variants in ButtonStyles, so the caller sets
  # the attribute and the styling follows.
  def style_class
    Buttons::ButtonStyles.classes(variant)
  end

  private

  def variant
    case style.to_s
    when "primary" then "primary"
    when "disabled" then "primary"
    else "secondary"
    end
  end
end
