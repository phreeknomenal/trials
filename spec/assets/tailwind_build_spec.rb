require "rails_helper"

# The suite, the linter and both scanners all passed while application.css did
# not compile: a "*/" inside a prose comment closed the comment early, and the
# rest of it parsed as CSS inside @theme. Nothing in CI builds the stylesheet,
# so a broken one would have shipped.
#
# This is slow by test standards and worth it, because the failure it catches is
# invisible to everything else.
RSpec.describe "The Tailwind stylesheet" do
  let(:stylesheet) { Rails.root.join("app/assets/builds/tailwind.css") }

  it "compiles" do
    output = `bin/rails tailwindcss:build 2>&1`

    expect($?.success?).to be(true), "tailwindcss:build failed:\n\n#{output}"
  end

  describe "the radius ladder" do
    # Each rung has to survive into the build, not just exist as a token. A rung
    # nothing uses is not emitted at all, which is correct, and the reason this
    # asserts only on rungs the app actually uses.
    %w[nav flash chip control card search panel].each do |rung|
      it "emits .rounded-#{rung}" do
        skip "stylesheet not built" unless File.exist?(stylesheet)

        expect(File.read(stylesheet)).to include(".rounded-#{rung}{")
      end
    end
  end

  # The pre-rebrand palette. If one of these reappears in the build, a class
  # naming it has come back somewhere.
  it "emits nothing from the pre-rebrand palette" do
    skip "stylesheet not built" unless File.exist?(stylesheet)

    expect(File.read(stylesheet)).not_to match(/\.(bg|text|border|ring)-(primary|secondary)-\d/)
  end
end
