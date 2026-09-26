require "rails_helper"

# Asserted section by section against the board, because three passes at this
# page each compared it at too coarse a grain and each missed something.
#
# The first compared section *lists* and fixed a duplicate. The second read the
# board's layout and fixed the shape. Only extracting the board's full element
# tree and diffing it against the rendered page turned up the header panel, the
# breadcrumb, Directions, the registry id and where the similar studies belong.
RSpec.describe "The study detail page against its board", type: :request do
  include TrialFixtures

  let(:nct_id) { fixture_ids.first }

  # A captured payload as the base, with the fields under test set explicitly.
  # The fixtures were captured before `last_update` existed and the first one is
  # a completed study with no sites, so leaving them implicit would test which
  # payload happened to be recorded rather than what the page renders.
  let(:study) do
    trial_fixture(nct_id).merge(
      status: "RECRUITING",
      last_update: "2026-09-01",
      locations_detailed: [
        {display: "University Hospital, Birmingham, Alabama", near_you: false},
        {display: "Regional Medical Center, Tuscaloosa, Alabama", near_you: false}
      ]
    )
  end

  before do
    allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(study)
    get "/search/#{nct_id}"
  end

  describe "the header" do
    # It was a full-width banner above the breadcrumb. The board's first panel
    # is inside the main column, which is why the page read as a different one:
    # a banner spanning the viewport over a two-column layout is page chrome,
    # and this is the study.
    it "is a panel inside the main column, not a banner above it" do
      main = response.body[/<main.*?<\/main>/m]

      expect(main).to include(ERB::Util.html_escape(study[:title]))
    end

    it "carries the recruitment status in its eyebrow" do
      expect(response.body).to match(/Recruiting/i)
    end

    # A registry entry is only as current as its last edit, and a reader has no
    # other way to know whether "recruiting" was confirmed last week or in 2019.
    it "says when the record was last touched" do
      expect(response.body).to match(/Record updated/i)
    end

    # The board's facts are a distance, a visit cadence and travel
    # reimbursement. The registry returns none of the three.
    it "shows no distance, visit cadence or travel claim" do
      expect(response.body).not_to match(/\d+\s*mi\b/)
      expect(response.body).not_to match(/Travel reimbursed/i)
      expect(response.body).not_to match(/Visits every/i)
    end
  end

  describe "the breadcrumb" do
    # It read "Home / Search / Nct06427018": three crumbs, and the one telling
    # you where you are was an accession number with a capital N.
    it "names the study rather than its registry id" do
      crumbs = response.body[/<ol.*?<\/ol>/m].to_s

      expect(crumbs).not_to match(/Nct\d+/)
      expect(crumbs).to include(ERB::Util.html_escape(study[:title].to_s.truncate(60, separator: " ")))
    end
  end

  describe "the main column" do
    # Signed in, because the match panel is the board's first section and it
    # only exists for somebody with a profile to match against. The rest of
    # these run signed out, which is the state four of the old sidebar's
    # anchors were broken in.
    it "runs in the board's order" do
      user = create(:user)
      user.profile.update!(onboarded: true, first_name: "Dana", last_name: "Whitfield", zip_code: "35201")
      sign_in user
      get "/search/#{nct_id}"

      wanted = ["You meet", "What this study is testing", "What taking part involves",
        "Where it takes place", "Who runs it"]

      headings = response.body.scan(/<h2[^>]*>\s*([^<]+)/).flatten.map(&:strip)
      seen = headings.filter_map { |h| wanted.find { |w| h.start_with?(w) } }.uniq

      expect(seen).to eq(wanted)
    end

    it "offers directions to each site rather than a distance it cannot compute" do
      expect(response.body).to include("google.com/maps")
      expect(response.body).to include("Directions")
    end

    it "gives the registry id and a way back to the registry record" do
      expect(response.body).to include("Registry ID")
      expect(response.body).to include("clinicaltrials.gov/study/#{nct_id}")
    end
  end

  describe "the aside" do
    let(:aside) { response.body[/<aside.*?<\/aside>/m].to_s }

    it "leads with what to do next" do
      expect(aside).to include("Contact the study team")
    end

    it "explains what follows contacting them" do
      expect(aside).to include("What happens next")
    end

    # The board's primary button is "Send my details". The app does not transmit
    # anything to a study team, and About, the privacy policy and the FAQ all
    # say so. A button here would have made three shipped pages lies.
    it "never offers to send anything on the reader's behalf" do
      expect(aside).not_to match(/Send my details/i)
      expect(aside).to include("nothing about you is sent")
    end
  end
end
