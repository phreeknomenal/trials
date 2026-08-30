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

# No separate worker process, and no Solid Queue. SOLID_QUEUE_IN_PUMA forks a
# supervisor, worker, dispatcher, and scheduler -- ~665MB on top of Puma's
# 231MB, against a 512MB dyno. Production uses queue_adapter = :async instead,
# which runs jobs in Puma's own thread pool. See config/environments/production.rb.
# The solid_queue gem and bin/jobs stay for if a worker dyno is added later.
web: bundle exec puma -C config/puma.rb
