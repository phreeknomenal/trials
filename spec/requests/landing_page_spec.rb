require "rails_helper"

# The landing page is the one every visitor sees first, and the board it was
# built from asks for four things the app cannot back. Each is asserted here
# rather than trusted to a comment, because the next person to reach for the
# board will find them drawn and plausible.
RSpec.describe "The landing page", type: :request do
  before { get root_path }

  it "renders" do
    expect(response).to have_http_status(:ok)
  end

  describe "the hero" do
    it "leads with the search rather than a list nobody asked for" do
      expect(response.body).to include("Where patients find trials worth their time")
      expect(response.body).to include(%(action="#{search_index_path}"))
    end

    it "searches on the two things the registry actually accepts" do
      expect(response.body).to include("Condition", "Location")
    end

    # There is no distance anywhere in the data. locations_detailed carries a
    # near_you boolean from a string match on city and state, and nothing reads
    # a distance param.
    it "offers no distance control" do
      expect(response.body).not_to match(/Within \d+ miles/)
      expect(response.body).not_to include("Any distance")
    end

    # The board's hero badge says "Now indexing studies in all 50 states".
    # Nothing is indexed: every search is a live query to the registry.
    it "does not claim to index anything" do
      expect(response.body).not_to match(/indexing/i)
      expect(response.body).not_to match(/all 50 states/i)
    end
  end

  describe "browse by condition" do
    # Seeded here rather than relied on: the test database carries no
    # conditions, and a spec that passes against an empty table would assert
    # nothing about a section whose whole job is listing them.
    let!(:conditions) do
      ["breast cancer", "lupus", "type 2 diabetes"].map { |name| Condition.create!(name: name) }
    end

    before { get root_path }

    it "offers every seeded condition" do
      conditions.each do |condition|
        expect(response.body).to include(ERB::Util.html_escape(condition.name))
      end
    end

    it "points each one at a real search" do
      conditions.each do |condition|
        expect(response.body).to include(
          ERB::Util.html_escape(search_index_path(condition: condition.name))
        )
      end
    end

    it "says how many there are rather than implying a corpus count" do
      expect(response.body).to include("3 conditions to start from")
    end

    # The board puts a trial count on every category card: 820, 640, 410. They
    # are invented, and they cannot be produced. parse_response sets total_count
    # to the length of the page it just fetched, with the comment "API v2
    # doesn't provide totalCount, use page count", so anyone wiring a card to it
    # would print the page size on every one.
    it "puts no trial count on anything" do
      expect(response.body).not_to match(/\d[\d,]* trials\b/)
    end
  end

  describe "what you can count on" do
    # This was false until the registry was asked for a status. A search had
    # been returning mostly completed studies, so the page would have promised
    # something the product did not do.
    it "claims open studies only, which is now true" do
      expect(response.body).to include("Open studies only")
      expect(TrialStatus::ACCEPTING).to include("recruiting")
      expect(TrialStatus::ACCEPTING).not_to include("completed")
    end
  end

  describe "the FAQ block" do
    it "reads the same list the FAQ page renders" do
      shown = Faq.entries.reject(&:unanswered?).first(PublicController::FAQ_COUNT)

      shown.each { |entry| expect(response.body).to include(ERB::Util.html_escape(entry.question)) }
    end

    it "never shows a question that has no answer yet" do
      Faq.unanswered.each do |entry|
        expect(response.body).not_to include(ERB::Util.html_escape(entry.question))
      end
    end

    it "sends people to the full FAQ for the rest" do
      expect(response.body).to include(faq_path)
    end
  end

  # Ten photo slots across this page and the stories, none of them licensed or
  # consented. The page had been filling them from picsum.photos, a third-party
  # service returning whatever it liked, so every visitor's browser made a
  # request to it and a health product showed an onion and a footbridge.
  describe "imagery" do
    it "fetches no images from a placeholder service" do
      expect(response.body).not_to include("picsum.photos")
    end

    it "loads no images from another host at all" do
      external = response.body.scan(/<img[^>]+src="(https?:\/\/[^"]+)"/).flatten

      expect(external).to be_empty
    end
  end

  # Three "Learn More" links went to "#". Same dead end as the footer links that
  # PR #147 replaced.
  describe "links" do
    it "has no link pointing at nothing" do
      expect(response.body).not_to match(/href="#"/)
    end

    it "resolves every in-page anchor to a section that renders" do
      targets = response.body.scan(/href="#([^"]+)"/).flatten.uniq
      ids = response.body.scan(/\sid="([^"]+)"/).flatten.uniq

      expect(targets - ids).to be_empty
    end
  end
end
