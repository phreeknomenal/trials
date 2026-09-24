require "rails_helper"

RSpec.describe Shared::FlashMessagesComponent, type: :component do
  def with_flash(pairs)
    render_inline(described_class.new(flash: pairs))
  end

  it "renders nothing when there is no message" do
    with_flash({})

    expect(page).to have_no_css("#main-flash-messages")
  end

  it "renders nothing for a key it does not recognise" do
    with_flash({"timedout" => "Session expired"})

    expect(page).to have_no_css("#main-flash-messages")
  end

  it "skips a key whose message is blank" do
    with_flash({"notice" => ""})

    expect(page).to have_no_css("#main-flash-messages")
  end

  # The bug this was fixed for. role=alert is assertive, so a success message
  # used to cut off whatever a screen reader was already saying.
  describe "politeness" do
    it "announces a success politely" do
      with_flash({"notice" => "Saved."})

      expect(page.find("[role]")[:role]).to eq("status")
    end

    it "announces an error assertively" do
      with_flash({"alert" => "Could not save."})

      expect(page.find("[role]")[:role]).to eq("alert")
    end

    it "announces a warning politely" do
      with_flash({"warning" => "This study stopped recruiting."})

      expect(page.find("[role]")[:role]).to eq("status")
    end
  end

  describe "tones" do
    it "supports a warning, which previously had to pose as a success or an error" do
      with_flash({"warning" => "This study stopped recruiting."})

      expect(page).to have_text("This study stopped recruiting.")
      expect(page.find("[role]")[:class]).to include("border-warn")
    end

    it "supports an informational message" do
      with_flash({"info" => "Scores were recalculated."})

      expect(page.find("[role]")[:class]).to include("border-info")
    end

    it "treats success and notice the same" do
      with_flash({"success" => "Saved."})

      expect(page.find("[role]")[:class]).to include("border-good")
    end

    it "treats error and alert the same" do
      with_flash({"error" => "Could not save."})

      expect(page.find("[role]")[:class]).to include("border-crit")
    end
  end

  # Colour alone fails for colourblind users and in forced-colors mode.
  it "carries an icon and a hidden tone label, not just a colour" do
    with_flash({"alert" => "Could not save."})

    expect(page).to have_css("svg", visible: :all)
    expect(page.find(".sr-only").text).to eq("Error:")
  end

  it "offers a labelled dismiss control" do
    with_flash({"notice" => "Saved."})

    expect(page.find("button")[:"aria-label"]).to eq("Dismiss success message")
  end

  it "puts the error first when a request produced both" do
    with_flash({"notice" => "Saved.", "alert" => "But the score failed to update."})

    roles = page.all("[role]").map { |node| node[:role] }
    expect(roles).to eq(["alert", "status"])
  end

  # Every tone painted its message in exactly the colour of the panel behind it
  # in dark mode: `dark:bg-crit-on-dark dark:text-crit-on-dark`, a contrast ratio
  # of 1 to 1. All four tones, every flash in the app, and each one returned 200
  # with the right words in it.
  #
  # The light side had it right the whole time -- `bg-good/10 text-good` -- and
  # the opacity modifier was simply dropped when the dark pairs were added.
  describe "dark mode" do
    it "tints the background rather than filling it with the text colour" do
      described_class::PRESENTATION.each do |tone, presentation|
        classes = presentation.fetch(:classes)
        background = classes[/dark:bg-\S+/]
        text = classes[/dark:text-\S+/]

        expect(background).to be_present, "#{tone} has no dark background"
        expect(background).to match(%r{/\d+\z}),
          "#{tone}'s dark background is #{background}, at full strength. " \
          "Without an opacity modifier it is the same colour as #{text}."
      end
    end

    it "never paints the text in the background's own colour at full strength" do
      described_class::PRESENTATION.each_value do |presentation|
        classes = presentation.fetch(:classes)
        background = classes[/dark:bg-(\S+)/, 1]
        text = classes[/dark:text-(\S+)/, 1]

        expect(background).not_to eq(text)
      end
    end

    it "gives every tone a dark border, background and text" do
      described_class::PRESENTATION.each do |tone, presentation|
        %w[border bg text].each do |property|
          expect(presentation.fetch(:classes)).to include("dark:#{property}-"),
            "#{tone} has no dark #{property}"
        end
      end
    end
  end
end
