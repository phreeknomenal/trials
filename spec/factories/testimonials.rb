# == Schema Information
#
# Table name: testimonials
#
#  id          :bigint           not null, primary key
#  author_name :string           not null
#  author_role :string
#  placeholder :boolean          default(FALSE), not null
#  position    :integer          default(0), not null
#  published   :boolean          default(FALSE), not null
#  quote       :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_testimonials_on_published_and_position  (published,position)
#
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
