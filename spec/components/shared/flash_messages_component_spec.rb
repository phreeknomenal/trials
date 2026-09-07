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
      expect(page.find("[role]")[:class]).to include("border-amber-600")
    end

    it "supports an informational message" do
      with_flash({"info" => "Scores were recalculated."})

      expect(page.find("[role]")[:class]).to include("border-blue-600")
    end

    it "treats success and notice the same" do
      with_flash({"success" => "Saved."})

      expect(page.find("[role]")[:class]).to include("border-green-600")
    end

    it "treats error and alert the same" do
      with_flash({"error" => "Could not save."})

      expect(page.find("[role]")[:class]).to include("border-red-600")
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
end
