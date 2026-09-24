require "rails_helper"

# Reads the palette out of application.css and checks the -on-dark pairs against
# the thing they exist for.
#
# `--color-ink-4-on-dark` was #68738A, which is `--color-ink-3`'s *light* value.
# The pair was inverted: the dimmest ink got darker on a dark ground instead of
# lighter, so every use of it sat at 3.66:1 against a 4.5 requirement. Nothing
# caught it because each token is individually a perfectly good grey, and the
# suite never renders a colour.
#
# These are arithmetic, not opinion. A pair that inverts is wrong whatever it
# looks like on the day.
RSpec.describe "The dark palette" do
  def source = Rails.root.join("app/assets/tailwind/application.css")

  def tokens
    @tokens ||= source.read.scan(/--color-([a-z0-9-]+):\s*(#[0-9A-Fa-f]{6})/)
      .to_h { |name, hex| [name, hex.downcase] }
  end

  # WCAG relative luminance.
  def luminance(hex)
    channels = hex.delete("#").scan(/../).map { |c| c.to_i(16) / 255.0 }
    r, g, b = channels.map { |c| (c <= 0.03928) ? c / 12.92 : ((c + 0.055) / 1.055)**2.4 }
    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  def contrast(a, b)
    l1, l2 = [luminance(a), luminance(b)].sort.reverse
    (l1 + 0.05) / (l2 + 0.05)
  end

  # The ground a token is read against in each theme.
  def light_ground = "#ffffff"

  def dark_ground = "#141a26"

  def pairs
    tokens.keys.filter_map do |name|
      next unless name.end_with?("-on-dark")

      base = name.delete_suffix("-on-dark")
      [base, name] if tokens.key?(base)
    end
  end

  it "defines a companion for every token that needs one" do
    expect(pairs).not_to be_empty
  end

  # The bug this file was written for. `--color-ink-4-on-dark` was #68738A,
  # which is `--color-ink-3`'s *light* value, so the dimmest ink got darker on a
  # dark ground instead of lighter and every use of it sat at 3.66:1.
  #
  # The check is contrast against the ground each token is read on, not a
  # "dark companion must be lighter" rule. That rule is a useful instinct and a
  # bad test: it is simply false for `line-*`, where a hairline is meant to sit
  # just off its background in both directions.
  describe "ink on the dark surface" do
    it "keeps every dark ink readable" do
      failing = tokens.select { |name, _| name.start_with?("ink") && name.end_with?("-on-dark") }
        .map { |name, hex| [name, contrast(hex, dark_ground).round(2)] }
        .reject { |_, ratio| ratio >= 4.5 }

      expect(failing).to be_empty,
        -> { failing.map { |name, ratio| "#{name} is #{ratio}:1 on the dark surface, needs 4.5:1" }.join("\n") }
    end

    it "keeps the dark inks distinguishable from each other" do
      steps = %w[ink-on-dark ink-2-on-dark ink-3-on-dark ink-4-on-dark]
        .select { |n| tokens.key?(n) }
        .map { |n| luminance(tokens[n]) }

      expect(steps).to eq(steps.sort.reverse),
        "the dark ink ramp is out of order: each step should be dimmer than the last"
    end
  end

  # ink-4 is the dimmest step and is 2.98:1 on white, which is below AA for text.
  # It cannot be fixed by darkening: the value that clears 4.5:1 on white is
  # #6A7589, which is ink-3, so the ramp would lose a step.
  #
  # That makes it a decorative and disabled-state token rather than a text one,
  # and it is currently used for text in a handful of places. Recorded as its own
  # task rather than swept into a dark-mode PR, because it is a light-mode
  # problem and fixing it means deciding what those places should say instead.
  describe "the light inks" do
    it "keeps every ink meant for text readable on white" do
      failing = tokens.select { |name, _| name.start_with?("ink") && !name.end_with?("-on-dark") }
        .except("ink-4")
        .map { |name, hex| [name, contrast(hex, light_ground).round(2)] }
        .reject { |_, ratio| ratio >= 4.5 }

      expect(failing).to be_empty,
        -> { failing.map { |name, ratio| "#{name} is #{ratio}:1 on white, needs 4.5:1" }.join("\n") }
    end

    it "still records what ink-4 is, so the exemption cannot quietly widen" do
      expect(contrast(tokens.fetch("ink-4"), light_ground)).to be < 4.5
    end
  end

  # The browser paints scrollbars, date pickers and select dropdowns itself, and
  # without this it paints them for a light page. The Trix toolbar's horizontal
  # scrollbar was a bright strip across a dark editor.
  describe "color-scheme" do
    it "tells the browser which way round each theme is" do
      css = source.read

      expect(css).to match(/:root\s*\{[^}]*color-scheme:\s*light/m)
      expect(css).to match(/\.dark\s*\{[^}]*color-scheme:\s*dark/m)
    end
  end
end
