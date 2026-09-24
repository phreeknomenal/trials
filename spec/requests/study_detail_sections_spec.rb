require "rails_helper"

# The study detail page answers three different questions and used to answer one
# of them twice.
#
#   - how the score was arrived at   -> MatchScoreCardComponent, from score_breakdown
#   - which criteria you meet        -> CriteriaSplitComponent, from EligibilityChecker
#   - what the study's status means  -> StatusMessageComponent
#
# StatusMessageComponent also rendered a "Your Match Factors" grid built from
# score_breakdown: the same six factors, from the same hash, that the score card
# draws as progress bars two panels above. One page, one set of numbers, two
# visual languages, and a reader with no way to know they were looking at the
# same thing twice.
#
# PR 5 added the criteria split without removing what the redesign superseded,
# which is the same shape as the footer's dead links and the duplicated status
# badge helper: adding the new thing is visible work and deleting the old one is
# not, so it gets skipped and nothing reports it.
RSpec.describe "Study detail sections", type: :request do
  include TrialFixtures

  let(:nct_id) { fixture_ids.first }
  let(:study) { trial_fixture(nct_id) }

  before do
    allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(study)
    get "/search/#{nct_id}"
  end

  it "renders" do
    expect(response).to have_http_status(:ok)
  end

  it "keeps the status message, because a saved study that closed still opens here" do
    expect(response.body).to include("what-this-means-for-you")
  end

  # get_study is deliberately unfiltered, unlike search, so this section is the
  # only thing that tells someone a study they saved has since closed.
  it "does not show the scoring factors twice" do
    expect(response.body.scan("Your Match Factors")).to be_empty
  end

  it "still explains how the score was reached, in one place" do
    expect(response.body.scan("How the score breaks down").count).to be <= 1
  end

  # The old sections announced themselves in Title Case while everything the
  # redesign touched used sentence case.
  it "writes its headings the way the rest of the app does" do
    %w[Match\ Score\ Details Key\ Details What\ This\ Means\ For\ You Study\ Overview].each do |title_case|
      expect(response.body).not_to include(title_case)
    end
  end

  # PR 5 shipped two sidebar anchors pointing at sections that did not render.
  # The rail is longer than the board's, so it is worth re-checking here.
  it "points every sidebar link at a section that exists" do
    targets = response.body.scan(/href="#([^"]+)"/).flatten.uniq
    ids = response.body.scan(/\sid="([^"]+)"/).flatten.uniq

    expect(targets - ids).to be_empty
  end
end
