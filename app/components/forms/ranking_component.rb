class Forms::RankingComponent < ApplicationComponent
  attr_reader :form, :name, :label, :choices, :label_options, :choice_options

  def initialize(form, name, label, choices, label_options = {}, **choice_options)
    @form = form
    @name = name
    @label = label
    @choices = choices
    @label_options = merge_options(label_options, label_class_str)
    @choice_options = merge_options(choice_options, choice_class_str)
  end

  def merge_options(options, class_str)
    options.merge(class: "#{class_str} #{options[:class]}")
  end

  def choice_class_str
    "w-4 h-4 text-info bg-surface-2 border-line-2 focus:ring-info focus:ring-2"
  end

  def label_class_str
    "block text-md text-secondary-800"
  end
end
