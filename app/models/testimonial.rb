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
class Testimonial < ApplicationRecord
  has_one_attached :avatar

  validates :quote, presence: true
  validates :author_name, presence: true

  scope :published, -> { where(published: true) }
  scope :placeholder, -> { where(placeholder: true) }

  # Ordered by position, then id. The id tiebreak matters: Postgres guarantees
  # no ordering when positions are equal, so without it the display order could
  # change between requests.
  scope :ordered, -> { order(:position, :id) }

  # Up to two letters from the author's name, for the avatar fallback.
  # Single-word names are common in testimonials and yield one letter.
  def initials
    author_name.to_s.split.first(2).map { |part| part[0]&.upcase }.compact.join
  end
end
