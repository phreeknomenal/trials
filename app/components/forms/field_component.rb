class Forms::FieldComponent < ApplicationComponent
  attr_reader :form, :attribute, :field_type, :label, :options, :select_options

  def initialize(form:, attribute:, field_type: :text, label: nil, options: {}, select_options: nil)
    @form = form
    @attribute = attribute
    @field_type = field_type.to_sym
    @label = label
    @options = options
    @select_options = select_options
  end

  def merge_class(default_class)
    classes = [ default_class, options[:class] ].compact.join(" ")
    merged_options = options.dup
    merged_options[:class] = classes
    merged_options
  end

  private

  def input_field
    case field_type
    when :checkbox
      form.check_box(attribute, merge_class(checkbox_field_class), options[:checked_value] || "1")
    when :checkbox_with_description
      form.check_box(attribute, merge_class(checkbox_field_class), options[:checked_value] || "1")
    when :date
      form.date_field(attribute, merge_class(text_field_class))
    when :file
      form.file_field(attribute, merge_class(file_field_class))
    when :number
      form.number_field(attribute, merge_class(text_field_class))
    when :rich_text
      form.rich_text_area(attribute, merge_class(rich_text_field_class))
    when :select
      html_options = {}

      if options[:data]
        html_options[:data] = options[:data]
      end
      if options[:class]
        html_options[:class] = options[:class]
      end
      if options[:required]
        html_options[:required] = options[:required]
      end

      html_options[:class] = [ select_field_class, html_options[:class] ].compact.join(" ")

      form.select(attribute, select_options, options.except(:data, :class, :required), html_options)
    when :text
      form.text_field(attribute, merge_class(text_field_class))
    when :text_area
      form.text_area(attribute, merge_class(text_area_class))
    else
      form.text_field(attribute, merge_class(text_field_class))
    end
  end

  def field_label
    if label.present? && options[:required]
      "#{label} <span class='text-red-500'>*</span>".html_safe
    else
      label
    end
  end

  def checkbox_field_class
    "h-4 w-4 rounded border-zinc-200 dark:border-zinc-700 text-white focus:ring-lavender-600 form-check-input accent-lavender-600"
  end

  def checkbox_label_class
    "ms-1 text-sm font-medium text-zinc-900 dark:text-zinc-300 form-check-label"
  end

  def date_field_class
    "block w-full form-control bg-white border border-secondary-300 text-gray-900 text-sm rounded-lg focus:ring-primary-500 focus:border-primary-500"
  end

  def file_field_class
    "block w-full text-sm text-secondary-900 border border-secondary-300 rounded-lg cursor-pointer bg-secondary-50 focus:outline-none focus:ring-primary file:bg-secondary-800"
  end

  def rich_text_field_class
    "prose p-2 max-w-none w-full rounded-lg text-zinc-900 dark:text-zinc-300 border-secondary-200 dark:border-zinc-700 focus:border-primary focus:ring-primary text-sm"
  end

  def select_field_class
    "block p-2 w-full bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-700 placeholder:text-zinc-500 dark:placeholder:text-zinc-400 text-sm text-zinc-900 dark:text-zinc-300 rounded focus:ring-lavender-600 focus:border-lavender-600 disabled:bg-lavender-50 disabled:text-lavender-500 disabled:border-lavender-200 disabled:shadow-none"
  end

  def text_field_class
    "block w-full form-control bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-300 text-sm rounded focus:ring-lavender-600 focus:border-lavender-600 p-2 disabled:bg-lavender-50 disabled:text-lavender-500 disabled:border-lavender-200 disabled:shadow-none"
  end

  def text_area_class
    "block w-full h-36 form-control bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-300 text-sm rounded focus:ring-lavender-600 focus:border-lavender-600 p-2"
  end
end
