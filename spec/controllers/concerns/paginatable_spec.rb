require "rails_helper"

RSpec.describe Paginatable do
  let(:harness) do
    Class.new do
      include Paginatable

      attr_reader :params

      def initialize(params) = @params = params

      public :page_size, :current_page
    end
  end

  def with(params) = harness.new(params)

  describe "#page_size" do
    it "uses the default when no param is given" do
      expect(with({}).page_size).to eq(10)
    end

    it "honours a reasonable per_page" do
      expect(with({per_page: "25"}).page_size).to eq(25)
    end

    it "clamps an absurd per_page to the maximum" do
      expect(with({per_page: "100000"}).page_size).to eq(described_class::MAX_PAGE_SIZE)
    end

    # "abc".to_i is 0, and 0 is truthy, so a `|| default` fallback never fired
    # and this silently became a limit of zero -- which Pagy rejects.
    it "falls back to the default for a non-numeric per_page" do
      expect(with({per_page: "abc"}).page_size).to eq(10)
    end

    it "falls back to the default for zero" do
      expect(with({per_page: "0"}).page_size).to eq(10)
    end

    it "falls back to the default for a negative per_page" do
      expect(with({per_page: "-5"}).page_size).to eq(10)
    end

    it "falls back to the default for a blank per_page" do
      expect(with({per_page: ""}).page_size).to eq(10)
    end

    it "never returns a value Pagy would reject" do
      %w[abc 0 -5 100000 1].each do |value|
        expect(with({per_page: value}).page_size).to be >= described_class::MIN_PAGE_SIZE
      end
    end
  end

  describe "#current_page" do
    it "defaults to 1" do
      expect(with({}).current_page).to eq(1)
    end

    it "reads a numeric page" do
      expect(with({page: "3"}).current_page).to eq(3)
    end

    it "floors a non-numeric or negative page at 1" do
      expect(with({page: "abc"}).current_page).to eq(1)
      expect(with({page: "-2"}).current_page).to eq(1)
    end
  end
end
