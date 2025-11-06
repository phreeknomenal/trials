class Forms::SliderComponent < ApplicationComponent
  erb_template <<~ERB
    <%= render Page::Widgets::Slider.new(name, label, options, **html_options) do %>
        <%= form.check_box name, html_options.merge(class: 'sr-only peer') %>
    <% end %>
  ERB

  attr_reader :form, :name, :label, :options, :html_options

  def initialize(form, name, label = nil, options = {}, **html_options)
    @form = form
    @name = name
    @label = label
    @options = options
    @html_options = html_options
  end
end
