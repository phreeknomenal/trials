class Seeds::Record::Race
  class << self
    def seed
      ActiveRecord::Base.transaction do
        existing_names = Race.pluck(:name)
        new_races = race_params.reject { |params| existing_names.include?(params[:name]) }

        unless new_races.empty?
          races = new_races.map { |params| Race.new(name: params[:name]) }
          Race.import(races)
        end
      end
    end

    private

    def race_params
      [
        { name: "American Indian or Alaska Native" },
        { name: "Asian" },
        { name: "Black or African American" },
        { name: "Native Hawaiian or Other Pacific Islander" },
        { name: "White" },
        { name: "Two or More Races" },
        { name: "Prefer not to say" }
      ]
    end
  end
end
