require "rails_helper"

# A duplicate or empty id is invalid HTML that fails silently. `getElementById`
# and an `href="#..."` both resolve to the first match, so the second section
# becomes unreachable and nothing anywhere reports it.
#
# The landing page had `id="intro"` twice and one `id=""`, on the page every
# visitor sees first. Nothing caught it because no in-page nav pointed at them
# yet, which is exactly the state the study detail page was in before PR 5 grew
# a sidebar and shipped two anchors to sections that did not render.
#
# This is the companion sweep to the anchor check in pages_spec: that one asks
# whether every link has a target, this one asks whether every target is
# unique. A page needs both to be true and neither implies the other.
RSpec.describe "Element ids", type: :request do
  def ids_on(body)
    body.scan(/\sid="([^"]*)"/).flatten
  end

  pages = {
    "the landing page" => "/",
    "about" => "/about",
    "the FAQ" => "/faq",
    "the privacy policy" => "/privacy",
    "the contact form" => "/contact"
  }

  pages.each do |name, path|
    describe name do
      before { get path }

      it "renders" do
        expect(response).to have_http_status(:ok)
      end

      it "uses no id twice" do
        duplicates = ids_on(response.body).tally.select { |_, count| count > 1 }.keys

        expect(duplicates).to be_empty,
          "#{name} reuses #{duplicates.join(", ")}. An href to it reaches the first one only."
      end

      it "leaves no id empty" do
        expect(ids_on(response.body)).to all(be_present)
      end
    end
  end

  # Named separately because the ids are the page's own structure rather than a
  # component's, and renaming one silently breaks any anchor added later.
  describe "the landing page sections" do
    it "names each always-on section for what it contains" do
      get "/"

      %w[hero how-it-works our-approach mission get-started].each do |id|
        expect(response.body).to include(%(id="#{id}"))
      end
    end

    # Community Stories is guarded on `@testimonials.any?`, so it is absent
    # rather than empty while no consented quotes exist. PR #136 stopped serving
    # the ten invented ones; the section comes back with real ones.
    it "omits the stories section rather than rendering it empty" do
      get "/"

      expect(response.body).not_to include(%(id="stories"))
    end

    it "renders the stories section once there is a quote to show" do
      create(:testimonial, published: true, placeholder: false)

      get "/"

      expect(response.body).to include(%(id="stories"))
    end
  end
end
