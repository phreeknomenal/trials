namespace :trials do
  desc "Recompute persisted match_score on saved trials (DRY_RUN=1 to preview)"
  task rescore: :environment do
    dry_run = ENV["DRY_RUN"].present?

    puts dry_run ? "Dry run -- no rows will be written." : "Rescoring saved trials..."

    result = SavedTrialRescorer.new(dry_run: dry_run, logger: ->(line) { puts "  #{line}" }).call

    puts "\nrescored: #{result.rescored}  skipped: #{result.skipped}  failed: #{result.failed}"
    result.errors.each { |error| warn "  ERROR #{error}" }

    exit(1) if result.failed.positive? && !dry_run
  end
end
