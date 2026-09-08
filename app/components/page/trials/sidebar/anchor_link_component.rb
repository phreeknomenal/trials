class Page::Trials::Sidebar::AnchorLinkComponent < ApplicationComponent
  erb_template <<-ERB
    <a href="<%= path %>" class="hover:text-sky-600"><%= text %></a>
  ERB

  attr_reader :path, :text

  def initialize(path:, text:)
    @path = path
    @text = text
  end
end
