require "rails_helper"

RSpec.describe "Devise configuration", type: :request do
  # Six characters is Devise's default and it is thin for an account holding a
  # diagnosis, a stage, a treatment history and a home ZIP, with no lockable
  # module slowing an online attempt either.
  describe "the password floor" do
    it "is ten characters" do
      expect(Devise.password_length.min).to eq(10)
    end

    it "refuses a nine character password" do
      user = User.new(email: "new@example.com", password: "123456789", password_confirmation: "123456789")

      expect(user).not_to be_valid
      expect(user.errors[:password].join).to match(/too short/)
    end

    it "accepts ten" do
      user = User.new(email: "new@example.com", password: "1234567890", password_confirmation: "1234567890")

      expect(user).to be_valid
    end

    # Validated on create and on change, so an existing account keeps working
    # until its owner next changes their password.
    it "leaves an existing short password alone" do
      user = create(:user)
      user.update_column(:encrypted_password, Devise::Encryptor.digest(User, "short1"))

      expect(user.reload).to be_valid
    end

    # The views read Devise.password_length rather than hardcoding a number, so
    # the hint cannot drift from the rule.
    it "tells someone signing up what the floor is" do
      get new_user_registration_path

      expect(response.body).to include("10 characters minimum")
    end
  end

  # Devise never routes to a template for a module that is not enabled, so these
  # were dead views that would drift out of step with the rest of the auth
  # screens and mislead whoever styled them next.
  describe "templates for modules that are not enabled" do
    it "does not enable confirmable" do
      expect(User.devise_modules).not_to include(:confirmable)
    end

    it "has no template left for anything confirmable would route to" do
      %w[
        app/views/devise/confirmations/new.html.erb
        app/views/devise/mailer/confirmation_instructions.html.erb
        app/views/devise/mailer/email_changed.html.erb
      ].each do |path|
        expect(Rails.root.join(path)).not_to exist
      end
    end

    # The shared links partial guards on the module flags, so removing the
    # templates cannot leave a link pointing at a route that does not exist.
    it "offers no link to a disabled module's screen" do
      get new_user_session_path

      expect(response.body).not_to include("confirmation instructions")
    end
  end

  # The ten character floor makes guessing a password offline expensive. This is
  # what makes guessing one against the live form pointless, which the app had
  # nothing for.
  describe "locking an account after repeated failures" do
    let(:user) { create(:user) }

    it "is enabled" do
      expect(User.devise_modules).to include(:lockable)
    end

    it "locks after ten failed attempts, not Devise's twenty" do
      expect(Devise.maximum_attempts).to eq(10)

      10.times { post user_session_path, params: {user: {email: user.email, password: "wrong-password"}} }

      expect(user.reload).to be_access_locked
    end

    it "leaves an account alone short of the limit" do
      9.times { post user_session_path, params: {user: {email: user.email, password: "wrong-password"}} }

      expect(user.reload).not_to be_access_locked
    end

    it "clears the count once someone signs in" do
      3.times { post user_session_path, params: {user: {email: user.email, password: "wrong-password"}} }
      post user_session_path, params: {user: {email: user.email, password: "password123"}}

      expect(user.reload.failed_attempts).to eq(0)
    end

    # Both strategies, so an hour's wait clears it without an email. Email only
    # would strand anyone whose unlock mail lands in spam.
    it "unlocks by email or by waiting" do
      expect(Devise.unlock_strategy).to eq(:both)
      expect(Devise.unlock_in).to eq(1.hour)
    end

    it "warns on the last attempt rather than locking without notice" do
      expect(Devise.last_attempt_warning).to be(true)
    end

    it "has a styled screen to ask for an unlock, not Devise scaffolding" do
      get new_user_unlock_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("unlocks on its own after that")
    end

    it "sends unlock instructions when asked" do
      user.lock_access!
      ActionMailer::Base.deliveries.clear

      post user_unlock_path, params: {user: {email: user.email}}

      expect(ActionMailer::Base.deliveries.last.to).to eq([user.email])
    end
  end

  # A password change is the one signal that someone else got in.
  describe "telling the account owner their password changed" do
    it "is on, rather than Devise's default of off" do
      expect(Devise.send_password_change_notification).to be(true)
    end

    it "keeps devise/mailer/password_change a live template" do
      expect(Rails.root.join("app/views/devise/mailer/password_change.html.erb")).to exist
    end

    it "sends one when the password changes" do
      user = create(:user)

      expect {
        user.update!(password: "a-new-long-password", password_confirmation: "a-new-long-password")
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(ActionMailer::Base.deliveries.last.to).to eq([user.email])
    end
  end
end
