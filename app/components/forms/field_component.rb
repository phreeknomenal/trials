# The interface is unchanged: 41 call sites pass form, attribute, field_type,
# label, options and select_options, and they all still work. What changed is
# that the classes come from Forms::FieldStyles rather than from nine
# hand-written strings that disagreed with each other, and that a field with a
# validation error now says so instead of rendering identically to a valid one.
class Forms::FieldComponent < ApplicationComponent
  attr_reader :form, :attribute, :field_type, :label, :options, :select_options, :hint

  def initialize(form:, attribute:, field_type: :text, label: nil, options: {}, select_options: nil, hint: nil)
    @form = form
    @attribute = attribute
    @field_type = field_type.to_sym
    @label = label
    @options = options
    @select_options = select_options
    @hint = hint
  end

  # The model is the source of truth for whether a field is in its error state.
  # Nothing has to remember to pass a flag.
  def errors
    return [] unless form.object.respond_to?(:errors)

    form.object.errors[attribute]
  end

  def invalid?
    errors.any?
  end

  def describedby
    ids = []
    ids << hint_id if hint.present?
    ids << error_id if invalid?
    ids.presence&.join(" ")
  end

  def hint_id = "#{field_id}-hint"

  def error_id = "#{field_id}-error"

  def field_id = "#{form.object_name}_#{attribute}".parameterize

  def merge_class(default_class)
    merged = options.dup
    merged[:class] = [default_class, options[:class]].compact.join(" ")
    merged[:"aria-invalid"] = true if invalid?
    merged[:"aria-describedby"] = describedby if describedby
    merged
  end

  private

  def input_field
    case field_type
    when :checkbox, :checkbox_with_description
      form.check_box(attribute, merge_class(checkbox_field_class), options[:checked_value] || "1")
    when :date
      form.date_field(attribute, merge_class(input_class))
    when :file
      form.file_field(attribute, merge_class(file_field_class))
    when :number
      form.number_field(attribute, merge_class(input_class))
    when :rich_text
      form.rich_text_area(attribute, merge_class(rich_text_field_class))
    when :select
      form.select(attribute, select_options, options.except(:data, :class, :required), select_html_options)
    when :text_area
      form.text_area(attribute, merge_class(text_area_class))
    else
      form.text_field(attribute, merge_class(input_class))
    end
  end

  # select takes its html options in a separate hash from its own options, which
  # is why it cannot go through merge_class like everything else.
  def select_html_options
    html = options.slice(:data, :required)
    html[:class] = [select_field_class, options[:class]].compact.join(" ")
    html[:"aria-invalid"] = true if invalid?
    html[:"aria-describedby"] = describedby if describedby
    html
  end

  def input_class = Forms::FieldStyles.input(invalid: invalid?)

  def select_field_class = Forms::FieldStyles.input(invalid: invalid?)

  def text_area_class = Forms::FieldStyles.input(invalid: invalid?, extra: "h-36")

  def file_field_class
    Forms::FieldStyles.input(
      invalid: invalid?,
      extra: "cursor-pointer file:mr-3 file:rounded-control file:border-0 " \
             "file:bg-navy-600 file:px-3 file:py-1.5 file:text-white file:font-medium"
    )
  end

  def rich_text_field_class
    Forms::FieldStyles.input(invalid: invalid?, extra: "prose max-w-none")
  end

  # Native, styled with accent-color rather than rebuilt from divs, so keyboard
  # behaviour, screen reader semantics and forced-colors mode keep working.
  def checkbox_field_class
    "h-4 w-4 rounded-sm border-line-2 dark:border-line-on-dark accent-sky-500 " \
      "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus"
  end

  def checkbox_label_class
    "ms-1 text-base font-medium text-ink dark:text-ink-2-on-dark"
  end

  def field_label
    return label unless label.present? && options[:required]

    safe_join([label, " ", tag.span("*", class: "text-crit", aria: {hidden: true}),
      tag.span("required", class: "sr-only")])
  end
end
