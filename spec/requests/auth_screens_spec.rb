require "rails_helper"

RSpec.describe "The auth screens", type: :request do
  let(:user) { create(:user) }

  # Six screens each carrying their own copy of the brand panel is how they stop
  # agreeing about what signing in buys.
  describe "the shared split" do
    {
      "sign in" => :new_user_session_path,
      "sign up" => :new_user_registration_path,
      "forgot password" => :new_user_password_path,
      "unlock" => :new_user_unlock_path
    }.each do |name, path_helper|
      it "renders on #{name}" do
        get public_send(path_helper)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Search works without an account")
      end
    end

    # A nav bar above a full height split offers a signed-out visitor links they
    # cannot use, and the boards show the brand panel running the whole height.
    it "uses a layout with no app header or footer" do
      get new_user_session_path

      expect(response.body).not_to include('aria-label="Main"')
    end
  end

  describe "sign in" do
    it "names neither field when the credentials are wrong" do
      post user_session_path, params: {user: {email: user.email, password: "wrong-password"}}

      expect(response.body).to include("do not match an account")
      expect(response.body).not_to include("Password is invalid")
    end

    # Paranoid mode tells a locked account exactly what it tells any other
    # failure, so nobody is told they are locked. Without a permanent link the
    # person would keep trying and never find the way out.
    it "offers the unlock route to everyone, so a locked account can find it" do
      get new_user_session_path

      expect(response.body).to include("Too many attempts lock an account")
      expect(response.body).to include(new_user_unlock_path)
    end

    it "renders the failure message inside the form column" do
      post user_session_path, params: {user: {email: user.email, password: "wrong-password"}}

      expect(response.body).to include("main-flash-messages")
    end
  end

  # The existence of an account is itself sensitive here: it says someone is
  # looking for a study.
  describe "not saying whether an address has an account" do
    it "is in paranoid mode" do
      expect(Devise.paranoid).to be(true)
    end

    it "answers a password reset the same way either way" do
      post user_password_path, params: {user: {email: user.email}}
      known = flash[:notice]

      post user_password_path, params: {user: {email: "nobody@example.com"}}

      expect(flash[:notice]).to eq(known)
      expect(known).to include("If an account exists")
    end

    # Six hours is config.reset_password_within, not a number typed into copy.
    it "says when the link expires" do
      post user_password_path, params: {user: {email: user.email}}

      expect(flash[:notice]).to include("six hours")
      expect(Devise.reset_password_within).to eq(6.hours)
    end

    it "answers an unlock request the same way either way" do
      post user_unlock_path, params: {user: {email: "nobody@example.com"}}

      expect(flash[:notice]).to include("If an account exists")
    end
  end

  describe "sign up" do
    it "reads the password floor from Devise rather than stating one" do
      get new_user_registration_path

      expect(response.body).to include("#{Devise.password_length.min} characters minimum")
    end
  end

  describe "account settings" do
    before { sign_in user }

    it "says what deleting the account takes with it" do
      get edit_user_registration_path

      expect(response.body).to include("your saved studies and your health profile")
    end
  end

  # devise_for draws its routes from User.devise_modules at the moment routes are
  # drawn. Rails reloads routes when config/routes.rb changes, not when the model
  # does, so a dev server running since before lockable was added has no unlock
  # helper at all and an unguarded link took the whole sign-in page down with
  # NoMethodError.
  #
  # The original spec could not catch it: the test process boots fresh, so the
  # helper always exists there. What it can catch is the same page rendered with
  # the module off, which is the state that made the call unsafe.
  describe "links to screens a module may not provide" do
    # devise_mapping returns this very object, so stubbing it is enough: there is
    # no need to reach into the controller.
    def without_module(name)
      allow(Devise.mappings[:user]).to receive(:"#{name}?").and_return(false)
    end

    it "renders sign in with lockable off" do
      without_module(:lockable)

      get new_user_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Unlock it by email")
    end

    it "renders sign in with recoverable off" do
      without_module(:recoverable)

      get new_user_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Forgot password?")
    end

    it "renders sign in with registerable off" do
      without_module(:registerable)

      get new_user_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Create an account")
    end

    it "still offers all three when every module is on" do
      get new_user_session_path

      expect(response.body).to include("Unlock it by email")
      expect(response.body).to include("Forgot password?")
      expect(response.body).to include("Create an account")
    end
  end

  # The first cut of this panel was a flat navy fill with white text, which
  # dropped the app's signature treatment entirely and made the split read as
  # two unrelated halves. A colour is hard to assert on; the backdrop it was
  # missing is not.
  describe "the panel treatment" do
    it "renders the gradient and shapes rather than a flat fill" do
      get new_user_session_path

      expect(response.body).to include("EDF2FB")
      expect(response.body).to include("auth-blob")
      expect(response.body).to include("auth-dots")
    end

    it "keeps the shapes out of the accessibility tree and out of the way of clicks" do
      get new_user_session_path

      expect(response.body).to include("pointer-events-none absolute inset-0")
    end

    # Slice, not meet: the shapes are meant to run off the edges, and letterboxing
    # them brings the whole composition into view, which is the look this avoids.
    it "crops the backdrop rather than fitting it" do
      get new_user_session_path

      expect(response.body).to include('preserveAspectRatio="xMidYMid slice"')
    end

    it "puts the panel text on ink rather than on white" do
      get new_user_session_path

      expect(response.body).to include("Everything you have looked at, in one place")
    end
  end
end
