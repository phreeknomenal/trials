# Heroku does not run migrations on deploy. Without this the app boots against
# an empty schema. db:prepare rather than db:migrate so the very first deploy
# also creates and loads the schema.
#
# db:seed runs separately because db:prepare only seeds when it *creates* the
# database -- on an existing one it runs migrations and stops. Without this,
# seed data added after the first deploy never reaches production.
#
# Everything in seed_production must therefore be idempotent, since it runs on
# every release. spec/lib/seeds/seed_production_spec.rb enforces that.
release: bundle exec rails db:prepare && bundle exec rails db:seed

# No separate worker process. Solid Queue runs inside Puma via the
# SOLID_QUEUE_IN_PUMA config var (see config/puma.rb), which keeps this on a
# single dyno. bin/jobs stays in the repo for when that is split out.
web: bundle exec puma -C config/puma.rb
