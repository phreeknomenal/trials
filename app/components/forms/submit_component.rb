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

  def style_class
    case style
    when :primary
      "flex items-center justify-center cursor-pointer text-white bg-primary hover:bg-primary-600 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-4 py-2"
    when :disabled
      "flex items-center justify-center cursor-pointer disabled:cursor-not-allowed rounded-lg border border-transparent bg-primary py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-primary-800 focus:outline-none focus:ring-2 cursor-pointer focus:ring-primary focus:ring-offset-2 disabled:bg-secondary-300 disabled:text-secondary-500 disabled:border-secondary-200 disabled:shadow-none"
    else
      "flex items-center justify-center cursor-pointer text-secondary-800 bg-secondary-300 hover:text-secondary-200 hover:bg-secondary-600 focus:ring-4 focus:ring-secondary-300 font-medium rounded-lg text-sm px-4 py-2 focus:outline-none"
    end
  end
end
