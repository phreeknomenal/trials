require "rails_helper"

RSpec.describe "Contact form", type: :request do
  let(:valid_params) do
    {contact_message: {name: "Dana Whitfield", email: "dana@example.com",
                       topic: "Using the app", body: "Does the match score update when I edit my profile?"}}
  end

  describe "GET /contact" do
    it "renders the form" do
      get contact_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Send message")
    end

    it "prefills what the app already knows for a signed-in user" do
      user = create(:user, email: "dana@example.com")
      user.profile.update!(first_name: "Dana", onboarded: true)
      sign_in user

      get contact_path

      expect(response.body).to include("dana@example.com")
    end

    it "prefills nothing for a signed-out visitor" do
      get contact_path

      expect(response.body).not_to match(/value="[^"]*@/)
    end
  end

  describe "POST /contact" do
    it "stores the message" do
      expect { post contact_path, params: valid_params }.to change(ContactMessage, :count).by(1)

      message = ContactMessage.last
      expect(message.name).to eq("Dana Whitfield")
      expect(message.email).to eq("dana@example.com")
      expect(message.topic).to eq("Using the app")
    end

    it "confirms in place, naming the address it will reply to" do
      post contact_path, params: valid_params

      expect(response).to have_http_status(:created)
      expect(response.body).to include("Message received", "dana@example.com")
    end

    it "arrives unanswered" do
      post contact_path, params: valid_params

      expect(ContactMessage.last).not_to be_answered
    end

    # The app cannot send email: production has smtp_settings commented out and
    # no environment sets a delivery method. If a mailer is ever added here it
    # must be added knowingly, because a mailer that no-ops would put this page
    # back to claiming a message was sent when it was not.
    it "sends no email, because the app cannot" do
      expect { post contact_path, params: valid_params }
        .not_to change(ActionMailer::Base.deliveries, :count)
    end

    describe "invalid input" do
      it "re-renders with the message intact rather than redirecting" do
        post contact_path, params: valid_params.deep_merge(contact_message: {email: "not-an-address"})

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Does the match score update")
      end

      it "rejects a topic that is not one of the options" do
        post contact_path, params: valid_params.deep_merge(contact_message: {topic: "<script>"})

        expect(ContactMessage.count).to eq(0)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects an empty message" do
        post contact_path, params: valid_params.deep_merge(contact_message: {body: ""})

        expect(ContactMessage.count).to eq(0)
      end
    end

    # A bot fills every input it can find, including the one positioned off
    # screen. It is dropped silently rather than rejected with an error, because
    # an error tells whoever wrote the bot which field to skip next time.
    describe "the honeypot" do
      it "drops a submission that filled the hidden field" do
        expect {
          post contact_path, params: valid_params.deep_merge(contact_message: {website: "http://spam.example"})
        }.not_to change(ContactMessage, :count)
      end

      it "still shows the confirmation, so the bot learns nothing" do
        post contact_path, params: valid_params.deep_merge(contact_message: {website: "http://spam.example"})

        expect(response).to have_http_status(:created)
        expect(response.body).to include("Message received")
      end

      it "never stores the honeypot value even on a real submission" do
        post contact_path, params: valid_params

        expect(ContactMessage.column_names).not_to include("website")
      end
    end
  end
end
