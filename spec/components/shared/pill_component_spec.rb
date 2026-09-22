require "rails_helper"

RSpec.describe Shared::PillComponent, type: :component do
  it "renders a button when it toggles in place" do
    render_inline(described_class.new(text: "Applying"))

    expect(page).to have_css("button[aria-pressed='false']", text: "Applying")
  end

  it "renders a link when it navigates" do
    render_inline(described_class.new(text: "Applying", path: "/saved_trials?status=applying"))

    expect(page).to have_css("a[href='/saved_trials?status=applying']")
    expect(page).to have_no_css("button")
  end

  it "says it is pressed when selected" do
    render_inline(described_class.new(text: "Applying", selected: true))

    expect(page).to have_css("button[aria-pressed='true']")
  end

  it "marks a selected link as current instead, aria-pressed meaning nothing there" do
    render_inline(described_class.new(text: "Applying", path: "/x", selected: true))

    expect(page.find("a")[:"aria-current"]).to eq("true")
    expect(page.find("a")[:"aria-pressed"]).to be_nil
  end

  # Selection is not colour alone.
  it "adds a check to a selected pill" do
    render_inline(described_class.new(text: "Applying", selected: true))

    expect(page).to have_css("svg")
  end

  it "shows a count beside the label" do
    render_inline(described_class.new(text: "Applying", count: 12))

    expect(page).to have_text("12")
  end

  # The one shape allowed to be fully round, because a pill never performs an
  # action. See the radius ladder.
  it "is fully round" do
    render_inline(described_class.new(text: "Applying"))

    expect(page.find("button")[:class]).to include("rounded-full")
  end
end
