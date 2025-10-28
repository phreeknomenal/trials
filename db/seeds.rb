if Rails.env.production?
  Seeds::Builder.new.seed_production
else
  Seeds::Builder.new.seed_development
end
