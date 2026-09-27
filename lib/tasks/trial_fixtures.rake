# The trial fixtures are real API responses run through ClinicalTrialClient, so
# they have to be re-fetched whenever the client starts keeping a field it used
# to drop. That had been a manual job, which is why the fixtures were three
# extractions behind the client by the time anything noticed.
#
# Each fixture records the URL it came from, so this needs no argument.
namespace :trial_fixtures do
  desc "Re-fetch every spec/fixtures/trials payload through the current client"
  task recapture: :environment do
    dir = Rails.root.join("spec/fixtures/trials")

    Dir.children(dir).grep(/\.json\z/).sort.each do |name|
      path = dir.join(name)
      payload = JSON.parse(path.read)
      meta = payload.fetch("_fixture")
      nct_id = meta.fetch("nct_id")

      study = ClinicalTrialClient.get_study(nct_id)

      if study[:error].present?
        warn "  #{nct_id}: #{study[:error]} — left as it was"
        next
      end

      meta["captured_at"] = Date.current.to_s
      path.write(JSON.pretty_generate({"_fixture" => meta, "study" => study}) + "\n")
      puts "  #{nct_id}: recaptured (#{Array(study[:locations_detailed]).length} locations)"

      # The registry asks for one request at a time from anonymous clients.
      sleep 0.5
    end
  end
end
