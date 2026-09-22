class Forms::PasswordComponent < ApplicationComponent
  attr_reader :form, :name, :options, :label

  def initialize(form, name, label, **options)
    @form = form
    @name = name
    @label = label
    @options = merge_options(options)
  end

  private

  def merge_options(options)
    existing_data = options[:data] || {}
    merged_data = existing_data.merge("password-visibility-target": "input")

    options.merge(
      class: "#{class_str} #{options[:class]}",
      type: "password",
      data: merged_data
    )
  end

  def class_str
    "block w-full min-w-0 flex-1 rounded-control border-line-2 text-ink-2 focus:border-focus focus-visible:outline-focus sm:text-sm"
  end
end
