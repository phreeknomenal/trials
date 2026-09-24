require "rails_helper"

RSpec.describe ClinicalTrialClient do
  # Stubs HTTParty's own get rather than the registry, so the assertion is about
  # what this class sends. The point of these specs is the query string.
  def stub_registry(studies: [])
    response = instance_double(HTTParty::Response, success?: true, code: 200,
      parsed_response: {"studies" => studies, "nextPageToken" => nil})
    allow(described_class).to receive(:get).and_return(response)
    response
  end

  describe ".advanced_search" do
    # The bug. It sent a condition and a location and nothing else, so the
    # registry returned everything it held. Across asthma, leukemia, diabetes
    # and migraine, 6% to 14% of the first hundred results were recruiting and
    # the largest group every time was COMPLETED. The app scored, ranked and
    # recommended studies that had already finished.
    it "asks the registry only for studies a person can act on" do
      stub_registry

      described_class.advanced_search(condition: "asthma")

      expect(described_class).to have_received(:get).with(
        "/studies", hash_including(query: hash_including(
          "filter.overallStatus" => "RECRUITING|NOT_YET_RECRUITING|ENROLLING_BY_INVITATION|AVAILABLE"
        ))
      )
    end

    it "reads the filter from TrialStatus rather than spelling it out" do
      stub_registry

      described_class.advanced_search(condition: "asthma")

      expect(described_class).to have_received(:get).with(
        "/studies", hash_including(query: hash_including(
          "filter.overallStatus" => TrialStatus.registry_filter
        ))
      )
    end

    it "sends the filter on a location-only search too" do
      stub_registry

      described_class.advanced_search(location: "Birmingham")

      expect(described_class).to have_received(:get).with(
        "/studies", hash_including(query: hash_including("filter.overallStatus"))
      )
    end

    it "still passes the condition and location through" do
      stub_registry

      described_class.advanced_search(condition: "asthma", location: "35201")

      expect(described_class).to have_received(:get).with(
        "/studies", hash_including(query: hash_including(
          "query.cond" => "asthma", "query.locn" => "35201"
        ))
      )
    end

    it "asks for nothing when it has neither term" do
      stub_registry

      described_class.advanced_search

      expect(described_class).not_to have_received(:get)
    end
  end

  # A saved study, or one reached by its id, is fetched whatever its status. If
  # a study a user saved has since completed, the page has to say so rather than
  # behave as though the study never existed.
  describe ".get_study" do
    it "does not filter by status" do
      stub_registry(studies: [{"protocolSection" => {}}])

      described_class.get_study("NCT01234567")

      expect(described_class).to have_received(:get) do |_path, options|
        expect(options[:query]).not_to have_key("filter.overallStatus")
      end
    end
  end

  # The term search had no callers and carried the same missing filter. Leaving
  # it would have been a trap: the next person to call it reintroduces the bug
  # this spec exists for.
  describe "the dead term search" do
    it "is gone" do
      expect(described_class).not_to respond_to(:search)
    end
  end
end
