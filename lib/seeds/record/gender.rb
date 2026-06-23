class Seeds::Record::Gender
  class << self
    def seed
      ActiveRecord::Base.transaction do
        existing_names = Gender.pluck(:name)
        new_genders = gender_params.reject { |params| existing_names.include?(params[:name]) }

        unless new_genders.empty?
          genders = new_genders.map { |params| Gender.new(name: params[:name]) }
          Gender.import(genders)
        end
      end
    end

    private

    def gender_params
      [
        {name: "Man"},
        {name: "Woman"},
        {name: "Non-Binary/Genderfluid"},
        {name: "Trans"},
        {name: "Prefer not to say"},
        {name: "Trans Man"},
        {name: "Trans Woman"}
      ]
    end
  end
end
