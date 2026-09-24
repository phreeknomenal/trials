# == Schema Information
#
# Table name: contact_messages
#
#  id          :bigint           not null, primary key
#  answered_at :datetime
#  body        :text             not null
#  email       :string           not null
#  name        :string           not null
#  topic       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_contact_messages_on_answered_at_and_created_at  (answered_at,created_at)
#
# A message from the contact form.
#
# It is stored rather than emailed because the app cannot send email: production
# has `smtp_settings` commented out and no other environment sets a delivery
# method. A form that says "we will reply" and quietly drops the message is
# worse than no form, so the page says what actually happens instead.
class ContactMessage < ApplicationRecord
  # Fixed rather than free text so the admin list can be filtered and so the
  # form cannot be used to inject a heading. Order is the order on the form.
  TOPICS = [
    "Using the app",
    "A study listing looks wrong",
    "My data or privacy",
    "Press or partnership",
    "Something else"
  ].freeze

  BODY_LIMIT = 5_000

  # The honeypot field. It is not a column and is never permitted, so nothing
  # reaches the database through it. It exists as an accessor only so the form
  # builder has something to render, because a bot that fills every input it can
  # find identifies itself by filling this one.
  attr_accessor :website

  validates :name, presence: true, length: {maximum: 120}
  validates :email, presence: true, length: {maximum: 255},
    format: {with: URI::MailTo::EMAIL_REGEXP, message: "does not look like an email address"}
  validates :topic, presence: true, inclusion: {in: TOPICS, message: "is not one of the options"}
  validates :body, presence: true, length: {maximum: BODY_LIMIT}

  scope :unanswered, -> { where(answered_at: nil) }
  scope :for_admin, -> { order(Arel.sql("answered_at IS NULL DESC"), created_at: :desc) }

  def answered? = answered_at.present?
end
