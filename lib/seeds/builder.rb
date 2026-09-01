class Seeds::Builder
  def seed_development
    ActiveRecord::Base.transaction do
      seed_production

      Seeds::Record::User.seed
      # Seeds::Record::Post.seed
      # Seeds::Record::Comment.seed
      # Seeds::Record::Like.seed
      # Seeds::Record::Activity.seed
      # Seeds::Record::FeatureFlag.seed
      # Seeds::Record::ActivityType.seed
      # Seeds::Record::Challenge.seed
    end
  end

  alias_method :seed_staging, :seed_development

  def seed_production
    ActiveRecord::Base.transaction do
      Seeds::Record::ZipCode.seed
      Seeds::Record::Gender.seed
      Seeds::Record::Race.seed
      Seeds::Record::Identity.seed
      Seeds::Record::Interest.seed
      Seeds::Record::Condition.seed
      Seeds::Record::Testimonial.seed
      # Seeds::Record::Tag.seed
      # Seeds::Record::Article.seed
      # Seeds::Record::Event.seed
    end
  end
end
