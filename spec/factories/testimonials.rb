FactoryBot.define do
  factory :testimonial do
    sequence(:author_name) { |n| "Author #{n} Lastname" }
    author_role { "Research participant" }
    quote { "Finding a trial that matched my situation took minutes instead of an afternoon." }
    sequence(:position) { |n| n }
    published { true }

    trait :unpublished do
      published { false }
    end

    trait :placeholder do
      placeholder { true }
    end

    trait :single_word_name do
      author_name { "Cher" }
    end
  end
end
