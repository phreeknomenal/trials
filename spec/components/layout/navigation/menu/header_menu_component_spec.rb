require "rails_helper"

RSpec.describe Layout::Navigation::Menu::HeaderMenuComponent, type: :component do
  # Stubbed on ApplicationComponent rather than the instance because the header
  # renders this component twice, and each nested instance resolves the
  # delegation on its own.
  def signed_in(value)
    allow_any_instance_of(ApplicationComponent).to receive(:user_signed_in?).and_return(value)
  end

  before { signed_in(false) }

  it "marks the link for the page being viewed" do
    with_request_url "/search" do
      render_inline(described_class.new)

      expect(page.find("a[aria-current='page']").text.strip).to eq("Find trials")
    end
  end

  # Not the root path: its authenticated/unauthenticated route constraints need
  # a Warden proxy that a component spec does not have.
  it "leaves links alone on any other page" do
    with_request_url "/onboarding" do
      render_inline(described_class.new)

      expect(page).to have_no_css("[aria-current]")
    end
  end

  it "gives every link a visible focus ring" do
    render_inline(described_class.new)

    expect(page.find("a")[:class]).to include("focus-visible:outline-2")
  end

  it "stacks the links when rendered vertically for the mobile panel" do
    render_inline(described_class.new(orientation: :vertical))

    expect(page.find("nav")[:class]).to include("flex-col")
  end

  it "lays the links out in a row by default" do
    render_inline(described_class.new)

    expect(page.find("nav")[:class]).not_to include("flex-col")
  end

  # Community pointed at "#" before this change.
  it "renders no link that points nowhere" do
    render_inline(described_class.new)

    expect(page).to have_no_css("a[href='#']")
  end

  it "offers the signed in destinations once authenticated" do
    signed_in(true)

    render_inline(described_class.new)

    expect(page).to have_link("My trials")
    expect(page).to have_link("Find trials")
    expect(page).to have_link("Saved")
  end

  # There were two search links pointing at two controllers that did the same
  # job. Signed in or out, there is now one search and one link to it.
  it "offers exactly one search link in both states" do
    render_inline(described_class.new)
    expect(page).to have_link("Find trials", count: 1)

    signed_in(true)
    render_inline(described_class.new)
    expect(page).to have_link("Find trials", count: 1)
  end
end
