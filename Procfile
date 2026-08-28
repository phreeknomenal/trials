# Heroku does not run migrations on deploy. Without this the app boots against
# an empty schema. db:prepare rather than db:migrate so the very first deploy
# also creates and loads the schema.
release: bundle exec rails db:prepare

# No separate worker process. Solid Queue runs inside Puma via the
# SOLID_QUEUE_IN_PUMA config var (see config/puma.rb), which keeps this on a
# single dyno. bin/jobs stays in the repo for when that is split out.
web: bundle exec puma -C config/puma.rb
