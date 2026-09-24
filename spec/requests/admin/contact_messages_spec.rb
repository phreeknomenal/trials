require "rails_helper"

RSpec.describe "Admin contact messages", type: :request do
  let(:admin) { create(:user, role: "admin") }

  def message(attrs = {})
    ContactMessage.create!(
      {name: "Dana Whitfield", email: "dana@example.com", topic: "Using the app",
       body: "Does the match score update when I edit my profile?"}.merge(attrs)
    )
  end

  describe "access" do
    it "is closed to a signed-out visitor" do
      get admin_contact_messages_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "is closed to an ordinary member" do
      user = create(:user, role: "member")
      user.profile.update!(onboarded: true)
      sign_in user

      get admin_contact_messages_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "the queue" do
    before { sign_in admin }

    it "lists a message with its sender, topic and body" do
      message

      get admin_contact_messages_path

      expect(response.body).to include("Dana Whitfield", "Using the app", "Does the match score update")
    end

    # Without this the contact form is a write-only table, which is no better
    # than the mailer that could not send.
    it "counts what is waiting" do
      message
      message(email: "second@example.com", answered_at: Time.current)

      get admin_contact_messages_path

      expect(response.body).to include("1 unanswered")
    end

    it "says plainly that nothing notifies anyone" do
      get admin_contact_messages_path

      expect(response.body).to include("no email is sent when one arrives")
    end

    it "filters to the unanswered" do
      message(email: "waiting@example.com")
      message(email: "done@example.com", answered_at: Time.current)

      get admin_contact_messages_path(filter: "unanswered")

      expect(response.body).to include("waiting@example.com")
      expect(response.body).not_to include("done@example.com")
    end

    it "says so when there is nothing to read" do
      get admin_contact_messages_path

      expect(response.body).to include("No messages yet")
    end
  end

  describe "marking one answered" do
    before { sign_in admin }

    it "stamps it" do
      record = message

      patch admin_contact_message_path(record)

      expect(record.reload).to be_answered
    end

    it "unstamps one marked by mistake" do
      record = message(answered_at: Time.current)

      patch admin_contact_message_path(record)

      expect(record.reload).not_to be_answered
    end

    it "keeps the filter the person was looking at" do
      record = message

      patch admin_contact_message_path(record, filter: "unanswered")

      expect(response).to redirect_to(admin_contact_messages_path(filter: "unanswered"))
    end
  end
end
