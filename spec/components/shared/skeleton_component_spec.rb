require "rails_helper"

RSpec.describe Shared::SkeletonComponent, type: :component do
  it "repeats the shape the given number of times" do
    render_inline(described_class.new(shape: :row, count: 4))

    expect(page).to have_css("span", count: 4)
  end

  # A screen reader should get "Loading studies" once, not a description of
  # twelve grey rectangles.
  it "hides the shapes and announces the label instead" do
    render_inline(described_class.new(shape: :row, count: 3, label: "Loading studies"))

    expect(page).to have_css("[aria-hidden='true']")
    expect(page).to have_css(".sr-only", text: "Loading studies")
    expect(page).to have_css("[role='status']")
  end

  it "announces nothing when it has no label" do
    render_inline(described_class.new(shape: :text))

    expect(page).to have_no_css("[role='status']")
  end

  # Reduced motion drops the pulse rather than slowing it: a persistent pulse is
  # what the setting exists to stop.
  it "stops animating under reduced motion" do
    render_inline(described_class.new(shape: :text))

    expect(page.find("span")[:class]).to include("motion-reduce:animate-none")
  end

  it "raises on a shape nobody defined" do
    expect { render_inline(described_class.new(shape: :blob)) }
      .to raise_error(ArgumentError, /Unknown skeleton shape/)
  end
end
