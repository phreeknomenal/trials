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
    classes = [default_class, options[:class]].compact.join(" ")
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

      html_options[:class] = [select_field_class, html_options[:class]].compact.join(" ")

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
      "#{label} <span class='text-crit'>*</span>".html_safe
    else
      label
    end
  end

  def checkbox_field_class
    "h-4 w-4 rounded border-line dark:border-line-on-dark text-white focus:ring-sky-500 form-check-input accent-sky-500"
  end

  def checkbox_label_class
    "ms-1 text-base font-medium text-ink dark:text-ink-2-on-dark form-check-label"
  end

  def date_field_class
    "block w-full form-control bg-surface border border-secondary-300 text-ink text-base rounded-lg focus:ring-primary-500 focus:border-primary-500"
  end

  def file_field_class
    "block w-full text-base text-secondary-900 border border-secondary-300 rounded-lg cursor-pointer bg-secondary-50 focus:outline-none focus:ring-primary file:bg-secondary-800"
  end

  def rich_text_field_class
    "prose p-2 max-w-none w-full rounded-lg text-ink dark:text-ink-2-on-dark border-secondary-200 dark:border-line-on-dark focus:border-primary focus:ring-primary text-base"
  end

  def select_field_class
    "block p-2 w-full bg-surface dark:bg-paper-on-dark border border-line dark:border-line-on-dark placeholder:text-ink-3 dark:placeholder:text-ink-3-on-dark text-base text-ink dark:text-ink-2-on-dark rounded focus:ring-sky-500 focus:border-navy-600 disabled:bg-sky-50 disabled:text-sky-500 disabled:border-sky-200 disabled:shadow-none"
  end

  def text_field_class
    "block w-full form-control bg-surface dark:bg-paper-on-dark border border-line dark:border-line-on-dark text-ink dark:text-ink-2-on-dark text-base rounded focus:ring-sky-500 focus:border-navy-600 p-2 disabled:bg-sky-50 disabled:text-sky-500 disabled:border-sky-200 disabled:shadow-none"
  end

  def text_area_class
    "block w-full h-36 form-control bg-surface dark:bg-paper-on-dark border border-line dark:border-line-on-dark text-ink dark:text-ink-2-on-dark text-base rounded focus:ring-sky-500 focus:border-navy-600 p-2"
  end
end
