require "rails_helper"

# A data-controller naming a controller that does not exist is completely
# silent: no warning, no console error, correct-looking markup, and a control
# that does nothing when clicked. That is exactly how the profile photo control
# shipped, and it is the fifth of the six dead controls found in this project.
#
# An action naming a method the controller does not define, and a target the
# controller never declares, fail the same silent way.
#
# This reads the markup and the controllers and checks they agree. It cannot
# tell whether the controller's logic is correct — only that every wire has
# something on both ends.
RSpec.describe "Stimulus wiring" do
  let(:controller_dir) { Rails.root.join("app/javascript/controllers") }

  # Controllers the markup names that have never been written. Listed rather
  # than silenced: each is a control that renders, looks live and does nothing
  # when used, and each is in Tasks/trials-dead-stimulus-controllers.md. This
  # list only ever shrinks — a new name here means a new dead control shipped.
  let(:known_missing) { %w[password-visibility sortable] }

  def markup_files
    Dir.glob(Rails.root.join("app/{views,components}/**/*.{erb,rb}"))
  end

  # Only literal values. A name built by interpolation cannot be checked here,
  # and guessing at one would report a failure nobody can act on.
  def scan(pattern)
    markup_files.flat_map do |path|
      File.read(path).scan(pattern).map { |captures| [path.sub("#{Rails.root}/", ""), *captures] }
    end
  end

  def controller_source(identifier)
    path = controller_dir.join("#{identifier.tr("-", "_")}_controller.js")
    path.exist? ? path.read : nil
  end

  it "has a controller file for every data-controller" do
    missing = scan(/data-controller="([a-z0-9 -]+)"/)
      .flat_map { |file, value| value.split.map { |name| [file, name] } }
      .reject { |_file, name| controller_source(name) || known_missing.include?(name) }
      .map { |file, name| "#{file} names #{name}" }

    expect(missing).to be_empty,
      "No controller file for: #{missing.join(", ")}"
  end

  it "has a method for every action a data-action names" do
    missing = scan(/data-action="([^"]+)"/).flat_map { |file, value|
      value.scan(/([a-z0-9-]+)#([a-zA-Z0-9_]+)/).filter_map do |name, method|
        source = controller_source(name)
        next if source.nil? || source.match?(/^\s*(?:async\s+|static\s+|get\s+)*#{Regexp.escape(method)}\s*\(/)

        "#{file} calls #{name}##{method}"
      end
    }

    expect(missing).to be_empty,
      "Action with no method: #{missing.join(", ")}"
  end

  it "declares every target the markup asks for" do
    missing = scan(/data-([a-z0-9-]+)-target="([a-zA-Z0-9_ ]+)"/).filter_map { |file, name, targets|
      source = controller_source(name)
      next if source.nil?

      declared = source[/static\s+targets\s*=\s*\[(.*?)\]/m].to_s.scan(/["']([a-zA-Z0-9_]+)["']/).flatten
      undeclared = targets.split - declared
      next if undeclared.empty?

      "#{file} asks #{name} for #{undeclared.join(", ")}"
    }

    expect(missing).to be_empty,
      "Target never declared: #{missing.join(", ")}"
  end
end
