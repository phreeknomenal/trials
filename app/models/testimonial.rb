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

  # The database enforces this too, with a check constraint. This is here so the
  # admin form says so in words rather than raising a StatementInvalid.
  validate :placeholder_is_never_published

  scope :published, -> { where(published: true) }
  scope :placeholder, -> { where(placeholder: true) }

  # What the public is allowed to see, and the only scope a public-facing reader
  # should use. `published` alone was not enough: the seeded testimonials were
  # created with published: true and placeholder: true together, so ten invented
  # quotes with invented names rendered on the landing page.
  #
  # The rule belongs here rather than in the controller because the next reader
  # of this model will reach for `published` for the same reason the last one did.
  scope :publishable, -> { published.where(placeholder: false) }

  # Ordered by position, then id. The id tiebreak matters: Postgres guarantees
  # no ordering when positions are equal, so without it the display order could
  # change between requests.
  scope :ordered, -> { order(:position, :id) }

  # Up to two letters from the author's name, for the avatar fallback.
  # Single-word names are common in testimonials and yield one letter.
  def initials
    author_name.to_s.split.first(2).map { |part| part[0]&.upcase }.compact.join
  end

  private

  def placeholder_is_never_published
    return unless placeholder? && published?

    errors.add(:published, "cannot be turned on for a placeholder. Replace the quote with a real, consented one first.")
  end
end
