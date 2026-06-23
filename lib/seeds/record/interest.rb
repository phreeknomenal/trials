class Seeds::Record::Interest
  class << self
    def seed
      ActiveRecord::Base.transaction do
        existing_names = Interest.pluck(:name)
        new_interests = interest_params.reject { |params| existing_names.include?(params[:name]) }

        unless new_interests.empty?
          interests = new_interests.map { |params| Interest.new(name: params[:name]) }
          Interest.import(interests)
        end
      end
    end

    private

    def interest_params
      [
        {name: "clinical trials"},
        {name: "mental health"},
        {name: "chronic conditions"},
        {name: "rare diseases"},
        {name: "cancer research"},
        {name: "cardiovascular health"},
        {name: "diabetes"},
        {name: "women's health"},
        {name: "men's health"},
        {name: "child and adolescent health"},
        {name: "nutrition and wellness"},
        {name: "fitness and physical activity"},
        {name: "public health"},
        {name: "community engagement"},
        {name: "health equity"},
        {name: "medical innovation"},
        {name: "genomics and precision medicine"},
        {name: "vaccines and prevention"},
        {name: "aging and longevity"},
        {name: "sleep and recovery"},
        {name: "mental resilience"},
        {name: "social determinants of health"},
        {name: "digital health and technology"},
        {name: "caregiving resources"},
        {name: "patient stories"},
        {name: "clinical research careers"},
        {name: "health policy"},
        {name: "health education"},
        {name: "medical breakthroughs"},
        {name: "community health initiatives"}
      ]
    end
  end
end
