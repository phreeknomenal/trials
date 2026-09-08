require "rails_helper"

# Three separate bugs in this project have been a component naming an icon
# partial that does not exist: bookmark-outline in the save button, chevron_down
# and chevron_up in the ranking component, exclamation_circle in my_trials/show.
#
# None could fail loudly. This scans the source for every icon name referenced
# and asserts a partial backs it, so the next one fails here instead of in
# production.
icon_directory = Rails.root.join("app/views/shared/icons")

reference_patterns = [
  /IconComponent\.new\(\s*"([a-z0-9_]+)"/,
  /\bicon:\s*"([a-z0-9_]+)"/
]

referenced_icons = Rails.root.glob("app/**/*.{rb,erb}").flat_map { |file|
  contents = File.read(file)
  reference_patterns.flat_map { |pattern| contents.scan(pattern).flatten }
}.uniq.sort

RSpec.describe "shared/icons" do
  it "finds icon references to check, so the guard cannot pass by scanning nothing" do
    expect(referenced_icons.size).to be > 20
  end

  referenced_icons.each do |name|
    it "has a partial for #{name}" do
      expect(icon_directory.join("_#{name}.html.erb")).to exist
    end
  end
end
