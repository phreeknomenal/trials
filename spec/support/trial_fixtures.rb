# Loads the captured ClinicalTrials.gov payloads in spec/fixtures/trials.
#
# Fixtures are real API responses run through ClinicalTrialClient.get_study, so
# specs exercise the same shape the scorer sees in production rather than a hash
# written to match assumptions about the data.
module TrialFixtures
  FIXTURE_DIR = Rails.root.join("spec/fixtures/trials")

  module_function

  def trial_fixture(nct_id)
    payload = load_fixture(nct_id)
    payload.fetch(:study)
  end

  def trial_fixture_metadata(nct_id)
    load_fixture(nct_id).fetch(:_fixture)
  end

  def all_trial_fixtures
    fixture_ids.index_with { |id| trial_fixture(id) }
  end

  def fixture_ids
    Dir.children(FIXTURE_DIR)
      .grep(/\.json\z/)
      .map { |name| File.basename(name, ".json").upcase }
      .sort
  end

  def load_fixture(nct_id)
    path = FIXTURE_DIR.join("#{nct_id.downcase}.json")
    raise ArgumentError, "no trial fixture for #{nct_id}" unless path.exist?

    JSON.parse(path.read, symbolize_names: true)
  end
end

RSpec.configure do |config|
  config.include TrialFixtures
end
