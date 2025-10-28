# frozen_string_literal: true

# NOTE: only doing this in development as some production environments (Heroku)
# NOTE: are sensitive to local FS writes, and besides -- it's just not proper
# NOTE: to have a dev-mode tool do its thing in production.
if Rails.env.development?
  require "annotate_rb"

  task :set_annotation_options do
    # You can override any of these by setting an environment variable of the
    # same name.
    ENV["position_in_routes"] = "before"
    ENV["position_in_class"] = "before"
    ENV["position_in_test"] = "before"
    ENV["position_in_fixture"] = "before"
    ENV["position_in_factory"] = "before"
    ENV["show_indexes"] = "true"
    ENV["simple_indexes"] = "false"
    ENV["model_dir"] = "app/models"
    ENV["include_version"] = "false"
    ENV["require"] = ""
    ENV["exclude_tests"] = "false"
    ENV["exclude_fixtures"] = "false"
    ENV["exclude_factories"] = "false"
    ENV["ignore_model_sub_dir"] = "false"
    ENV["skip_on_db_migrate"] = "false"
    ENV["format_bare"] = "true"
    ENV["format_rdoc"] = "false"
    ENV["format_markdown"] = "false"
    ENV["sort"] = "false"
    ENV["force"] = "false"
    ENV["trace"] = "false"
  end

  Rake::Task["db:migrate"].enhance do
    Rake::Task["annotate_models"].invoke
  end

  Rake::Task["db:rollback"].enhance do
    Rake::Task["annotate_models"].invoke
  end

  desc "Add schema information (as comments) to model files"
  task annotate_models: :set_annotation_options do
    require "annotate_rb"
    system("bundle exec annotaterb models")
  end
end
