# Onboarding Flow Documentation

This document details the complete onboarding flow for the NOWINCLUDED application, including email verification, profile setup, and implementation guidance for building similar features in other applications.

---

## Table of Contents

1. [Overview](#overview)
2. [Flow Architecture](#flow-architecture)
3. [Email Verification Flow](#email-verification-flow)
4. [Profile Onboarding Flow](#profile-onboarding-flow)
5. [Technical Implementation](#technical-implementation)
6. [Building a Similar Feature](#building-a-similar-feature)

---

## Overview

The onboarding flow consists of two main phases:

1. **Email Verification**: Users verify their email address using a 6-digit OTP (One-Time Password) code
2. **Profile Completion**: Users complete their profile through a multi-step modal form

The system ensures users cannot access the main application until both phases are completed.

---

## Flow Architecture

### High-Level Flow Diagram

```
User Registration
    ↓
Email Verification (6-digit OTP)
    ↓
Email Confirmed → User Signed In
    ↓
Profile Onboarding Modal (if incomplete)
    ↓
Profile Completed → Full Access
```

### Key Components

- **User Model**: Handles authentication and email confirmation
- **Profile Model**: Stores user profile data and onboarding status
- **Email Verification Controller**: Manages OTP code verification
- **Profile Controller**: Handles profile updates and completion
- **Multi-Step Form Controller**: JavaScript controller for form navigation
- **Modal Controller**: JavaScript controller for modal display logic

---

## Email Verification Flow

### Step 1: User Registration

**Route**: `POST /users` (Devise registration)

**Process**:
1. User submits email, password, and password confirmation
2. User account is created with `confirmed_at: nil` (unconfirmed)
3. User is automatically signed in (but with limited access)
4. Confirmation code is generated and sent via email

**Key Code**:
```ruby
# app/models/user.rb
def generate_confirmation_code
  if confirmation_code.blank? || confirmation_code_expired?
    self.confirmation_code = rand.to_s[2..7].rjust(6, "0")
    self.confirmation_code_sent_at = Time.current
  end
  save(validate: false)
end

def send_confirmation_code
  generate_confirmation_code
  UserMailer.email_confirmation_code(self).deliver_later
end
```

### Step 2: Email Verification Page

**Route**: `GET /email_verification?email=user@example.com`

**Process**:
1. User is redirected to email verification page after signup
2. Page displays email address where code was sent
3. User enters 6-digit code
4. Code expires after 10 minutes

**Features**:
- Resend code functionality
- Code validation (6 digits, numeric only)
- Auto-redirect if user is already confirmed

### Step 3: Code Verification

**Route**: `POST /email_verification/verify`

**Process**:
1. User submits 6-digit code
2. System validates code:
   - Code matches stored confirmation_code
   - Code is not expired (within 10 minutes)
3. If valid:
   - User's `confirmed_at` is set
   - User is signed in
   - Redirected to root path
4. If invalid:
   - Error message displayed
   - User can retry or resend code

**Key Code**:
```ruby
# app/models/user.rb
def confirm_by_code!(code)
  return false if confirmation_code_expired?
  return false unless code == confirmation_code
  
  confirm # Devise method: sets confirmed_at etc.
end

def confirmation_code_expired?
  confirmation_code_sent_at < 10.minutes.ago
end
```

### Step 4: Login with Unconfirmed Email

**Route**: `POST /users/sign_in`

**Process**:
1. If user tries to login with unconfirmed email:
   - Password is validated
   - New confirmation code is sent
   - User redirected to email verification page
2. If email is confirmed:
   - Normal login flow proceeds

**Key Code**:
```ruby
# app/controllers/users/sessions_controller.rb
def create
  user = User.find_by(email: params[:user][:email])
  
  if user && !user.confirmed?
    if user.valid_password?(params[:user][:password])
      user.send_confirmation_code
      redirect_to email_verification_path(email: user.email)
    else
      redirect_to new_user_session_path, alert: "Invalid email or password."
    end
  else
    super # Normal login flow
  end
end
```

### Email Verification Features

- **6-digit OTP code**: Randomly generated, zero-padded
- **10-minute expiration**: Codes expire after 10 minutes
- **Resend functionality**: Users can request new codes
- **Single code per user**: New code replaces old one if not expired
- **Email delivery**: Asynchronous via ActiveJob

---

## Profile Onboarding Flow

### Profile Completion Check

**Method**: `Profile#profile_completed?`

**Requirements**:
1. `onboarded` flag must be `true`
2. `first_name` must be present
3. `last_name` must be present

**Key Code**:
```ruby
# app/models/profile.rb
def profile_completed?
  return false unless onboarded?
  
  required_fields = %i[first_name last_name]
  required_fields.all? { |field| send(field).present? }
end
```

### Modal Display Logic

**Location**: Rendered in main application layout

**Trigger**:
- Modal automatically shows if `current_profile.profile_completed?` returns `false`
- Controlled by Stimulus `modal_controller.js`

**Key Code**:
```erb
<!-- app/views/layouts/application.html.erb -->
<%= render "shared/profile_onboarding_modal" if current_profile %>
```

```javascript
// app/javascript/controllers/modal_controller.js
connect() {
  if (this.element.dataset.profileIncomplete === "true" && 
      this.element.id === "profile-onboarding-modal") {
    this.showModal();
  }
}
```

### Multi-Step Form Structure

The profile onboarding modal consists of **3 steps**:

#### Step 1: Basic Information

**Fields**:
- Profile picture (avatar) - optional
- First Name - **required**
- Last Name - **required**
- Gender - optional (dropdown)
- Date of Birth - optional (must be 18+ if provided)
- Zip Code - optional (5 digits)

**Validation**:
- First name and last name are required
- Date of birth must be at least 18 years ago
- Zip code must be 5 digits (numeric)

**Features**:
- Avatar preview with fallback to initials
- Real-time validation
- Next button disabled until required fields are filled

#### Step 2: Identities and Interests

**Fields**:
- Identities (checkboxes) - "I am a..."
  - Multiple selections allowed
  - Examples: Parent, Caregiver, Patient, etc.
- Interests (checkboxes) - "Looking for..."
  - Multiple selections allowed
  - Examples: Support Groups, Events, Resources, etc.

**Features**:
- All selections optional
- Visual checkbox styling
- Back button to return to Step 1

#### Step 3: Circle Selection

**Fields**:
- Health Circles (checkboxes)
  - Multiple selections allowed
  - Each circle represents a health topic community
  - At least one circle must be selected

**Validation**:
- At least one circle must be selected (required)

**Features**:
- Visual selection with checked state styling
- Informational text about circles
- Submit button appears on final step

### Form Submission

**Route**: `PATCH /profiles/:id`

**Process**:
1. All form data is submitted via Turbo Stream
2. Profile is updated with:
   - Basic information
   - Identity associations
   - Interest associations
   - Circle associations
   - `onboarded: true` flag
3. On success:
   - Modal is removed from DOM
   - Flash message displayed
   - Profile completion status updated

**Key Code**:
```ruby
# app/controllers/profiles_controller.rb
def update
  format.turbo_stream do
    if @profile.update(profile_params)
      flash[:notice] = "Your profile was successfully completed!"
      render turbo_stream: [
        turbo_stream.replace("main-flash-messages", partial: "shared/utilities/flash_messages"),
        turbo_stream.replace("profile-onboarding-modal", "")
      ]
    end
  end
end
```

### Multi-Step Form Controller

**File**: `app/javascript/controllers/multi_step_form_controller.js`

**Features**:
- Step navigation (next/previous)
- Real-time field validation
- Button state management (disabled/enabled)
- Progress tracking
- Avatar preview handling
- Circle selection validation

**Key Methods**:
- `next()`: Move to next step with validation
- `previous()`: Move to previous step
- `validateCurrentStep()`: Validate current step before proceeding
- `toggleNextButton()`: Enable/disable next button based on field completion
- `setupAvatarPreview()`: Handle avatar image preview

---

## Technical Implementation

### Database Schema

#### Users Table
- `email`: string (unique)
- `password_digest`: string
- `confirmed_at`: datetime (null if unconfirmed)
- `confirmation_code`: string (6-digit OTP)
- `confirmation_code_sent_at`: datetime

#### Profiles Table
- `user_id`: bigint (unique, foreign key)
- `onboarded`: boolean (default: false)
- `first_name`: string
- `last_name`: string
- `gender_id`: bigint (foreign key, optional)
- `birth_date`: date (optional)
- `zip_code`: string (optional)
- `avatar`: ActiveStorage attachment
- `header_image`: ActiveStorage attachment

#### Join Tables
- `profile_identities`: profile_id, identity_id
- `profile_interests`: profile_id, interest_id

### Controllers

#### EmailVerificationsController
- `show`: Display verification page
- `verify`: Validate and confirm OTP code
- `resend`: Send new OTP code

#### ProfilesController
- `update`: Handle profile updates and completion
- Supports HTML, Turbo Stream, and JSON formats

### Models

#### User Model
- Devise integration with `:confirmable` module
- Custom OTP confirmation system
- Methods: `generate_confirmation_code`, `send_confirmation_code`, `confirm_by_code!`

#### Profile Model
- `profile_completed?`: Checks completion status
- Associations: identities, interests, circles
- Validations: first_name, last_name (on update)

### JavaScript Controllers

#### Modal Controller (Stimulus)
- Manages modal visibility
- Handles form submission success
- Auto-shows modal for incomplete profiles

#### Multi-Step Form Controller (Stimulus)
- Manages 3-step form navigation
- Real-time validation
- Progress tracking
- Avatar preview

### Routes

```ruby
# Email verification
get "email_verification", to: "email_verifications#show"
post "email_verification/verify", to: "email_verifications#verify"
post "email_verification/resend", to: "email_verifications#resend"

# Profile updates
resources :profiles, only: [:show, :edit, :update, :destroy]
```

---

## Building a Similar Feature

### Step 1: Email Verification System

#### 1.1 Database Setup

**Migration**:
```ruby
class AddConfirmationFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :confirmation_code, :string
    add_column :users, :confirmation_code_sent_at, :datetime
    add_column :users, :confirmed_at, :datetime
  end
end
```

#### 1.2 User Model Updates

```ruby
class User < ApplicationRecord
  # Generate 6-digit OTP code
  def generate_confirmation_code
    if confirmation_code.blank? || confirmation_code_expired?
      self.confirmation_code = rand.to_s[2..7].rjust(6, "0")
      self.confirmation_code_sent_at = Time.current
    end
    save(validate: false)
  end

  # Check if code is expired (10 minutes)
  def confirmation_code_expired?
    return true if confirmation_code_sent_at.blank?
    confirmation_code_sent_at < 10.minutes.ago
  end

  # Verify and confirm code
  def confirm_by_code!(code)
    return false if confirmation_code_expired?
    return false unless code == confirmation_code
    
    update(confirmed_at: Time.current)
  end

  # Send confirmation code via email
  def send_confirmation_code
    generate_confirmation_code
    UserMailer.email_confirmation_code(self).deliver_later
  end

  # Check if user is confirmed
  def confirmed?
    confirmed_at.present?
  end
end
```

#### 1.3 Email Verification Controller

```ruby
class EmailVerificationsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @user = User.find_by(email: params[:email])
    redirect_to new_user_session_path unless @user && !@user.confirmed?
  end

  def verify
    @user = User.find_by(email: params[:email])
    
    if @user&.confirm_by_code!(params[:code])
      sign_in(@user)
      redirect_to root_path, notice: "Email confirmed successfully!"
    else
      redirect_to email_verification_path(email: params[:email]), 
                  alert: "Invalid or expired code."
    end
  end

  def resend
    @user = User.find_by(email: params[:email])
    
    if @user && !@user.confirmed?
      @user.send_confirmation_code
      redirect_to email_verification_path(email: @user.email), 
                  notice: "Code resent!"
    else
      redirect_to new_user_session_path
    end
  end
end
```

#### 1.4 Mailer

```ruby
class UserMailer < ApplicationMailer
  def email_confirmation_code(user)
    @user = user
    @confirmation_code = user.confirmation_code
    
    mail(
      to: @user.email,
      subject: "Confirm your email address"
    )
  end
end
```

#### 1.5 Routes

```ruby
get "email_verification", to: "email_verifications#show"
post "email_verification/verify", to: "email_verifications#verify"
post "email_verification/resend", to: "email_verifications#resend"
```

#### 1.6 Registration Flow Update

```ruby
class RegistrationsController < Devise::RegistrationsController
  def create
    super do |resource|
      if resource.persisted?
        resource.send_confirmation_code
        sign_out(resource) # Sign out until confirmed
        redirect_to email_verification_path(email: resource.email)
        return
      end
    end
  end
end
```

### Step 2: Profile Onboarding System

#### 2.1 Database Setup

**Migration**:
```ruby
class AddOnboardingToProfiles < ActiveRecord::Migration[7.2]
  def change
    add_column :profiles, :onboarded, :boolean, null: false, default: false
    add_column :profiles, :first_name, :string
    add_column :profiles, :last_name, :string
    add_column :profiles, :zip_code, :string
    add_column :profiles, :birth_date, :date
  end
end
```

#### 2.2 Profile Model

```ruby
class Profile < ApplicationRecord
  belongs_to :user
  has_many :profile_identities, dependent: :destroy
  has_many :identities, through: :profile_identities
  has_many :profile_interests, dependent: :destroy
  has_many :interests, through: :profile_interests
  has_many :circle_profiles, dependent: :destroy
  has_many :circles, through: :circle_profiles
  
  validates :first_name, presence: true, on: :update
  validates :last_name, presence: true, on: :update
  
  def profile_completed?
    return false unless onboarded?
    first_name.present? && last_name.present?
  end
end
```

#### 2.3 Multi-Step Form JavaScript (Stimulus)

```javascript
// app/javascript/controllers/multi_step_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "nextButton", "prevButton", "submitButton"]
  static values = {
    currentStep: { type: Number, default: 1 },
    totalSteps: { type: Number, default: 3 }
  }

  connect() {
    this.showCurrentStep()
  }

  next(event) {
    event.preventDefault()
    if (this.validateCurrentStep() && this.currentStepValue < this.totalStepsValue) {
      this.currentStepValue++
      this.showCurrentStep()
    }
  }

  previous() {
    if (this.currentStepValue > 1) {
      this.currentStepValue--
      this.showCurrentStep()
    }
  }

  validateCurrentStep() {
    const currentStep = this.stepTargets[this.currentStepValue - 1]
    const requiredFields = currentStep.querySelectorAll('[required]')
    
    return Array.from(requiredFields).every(field => {
      return field.value.trim() !== ''
    })
  }

  showCurrentStep() {
    this.stepTargets.forEach((step, index) => {
      step.classList.toggle("hidden", index + 1 !== this.currentStepValue)
    })
    
    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.classList.toggle(
        "hidden", 
        this.currentStepValue === this.totalStepsValue
      )
    }
    
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.classList.toggle(
        "hidden", 
        this.currentStepValue !== this.totalStepsValue
      )
    }
  }
}
```

#### 2.4 Modal Controller (Stimulus)

```javascript
// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form"]

  connect() {
    if (this.element.dataset.profileIncomplete === "true") {
      this.showModal()
    }
  }

  showModal() {
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.style.display = "flex"
  }

  closeModal(event) {
    event.preventDefault()
    this.modalTarget.style.display = "none"
  }

  handleSuccess(event) {
    const response = event.detail.fetchResponse
    if (response.succeeded) {
      this.closeModal(event)
      this.element.dataset.profileIncomplete = "false"
    }
  }
}
```

#### 2.5 Profile Controller Update

```ruby
class ProfilesController < ApplicationController
  def update
    respond_to do |format|
      format.turbo_stream do
        if @profile.update(profile_params)
          flash[:notice] = "Profile completed!"
          render turbo_stream: [
            turbo_stream.replace("profile-onboarding-modal", ""),
            turbo_stream.replace("flash-messages", partial: "shared/flash_messages")
          ]
        else
          render turbo_stream: turbo_stream.replace(
            "profile-form", 
            partial: "profiles/form", 
            locals: { profile: @profile }
          )
        end
      end
    end
  end

  private

  def profile_params
    params.require(:profile).permit(
      :onboarded, :first_name, :last_name, :zip_code, :birth_date,
      identity_ids: [],
      interest_ids: [],
      circle_ids: []
    )
  end
end
```

#### 2.6 Modal View Template

```erb
<!-- app/views/shared/_profile_onboarding_modal.html.erb -->
<div id="profile-onboarding-modal" 
     data-controller="modal multi-step-form" 
     data-profile-incomplete="<%= !current_profile.profile_completed? %>">
  
  <div data-modal-target="modal" class="hidden fixed inset-0 bg-gray-900 bg-opacity-70 z-50">
    <div class="flex items-center justify-center h-full">
      <div class="bg-white rounded-lg p-6 w-full max-w-md">
        
        <%= form_with model: current_profile, 
                     url: profile_path(current_profile), 
                     method: :patch,
                     data: { 
                       modal_target: "form",
                       action: "turbo:submit-end->modal#handleSuccess"
                     } do |f| %>
          
          <!-- Step 1: Basic Info -->
          <div data-multi-step-form-target="step">
            <h3>Complete Your Profile</h3>
            <%= f.text_field :first_name, required: true, placeholder: "First Name" %>
            <%= f.text_field :last_name, required: true, placeholder: "Last Name" %>
            <%= f.text_field :zip_code, placeholder: "Zip Code" %>
          </div>

          <!-- Step 2: Identities -->
          <div data-multi-step-form-target="step" class="hidden">
            <h3>Tell us who you are</h3>
            <!-- Identity checkboxes -->
          </div>

          <!-- Step 3: Circles -->
          <div data-multi-step-form-target="step" class="hidden">
            <h3>Select Circles</h3>
            <!-- Circle checkboxes -->
          </div>

          <%= f.hidden_field :onboarded, value: true %>

          <div class="flex justify-between mt-4">
            <button type="button" 
                    data-multi-step-form-target="prevButton"
                    data-action="multi-step-form#previous"
                    class="hidden">
              Previous
            </button>
            
            <button type="button"
                    data-multi-step-form-target="nextButton"
                    data-action="multi-step-form#next">
              Next
            </button>
            
            <%= f.submit "Complete", 
                class: "hidden",
                data: { multi_step_form_target: "submitButton" } %>
          </div>
        <% end %>
      </div>
    </div>
  </div>
</div>
```

### Step 3: Integration Points

#### 3.1 Application Layout

```erb
<!-- app/views/layouts/application.html.erb -->
<body>
  <!-- Main content -->
  <%= yield %>
  
  <!-- Onboarding modal -->
  <%= render "shared/profile_onboarding_modal" if current_profile %>
</body>
```

#### 3.2 Authentication Checks

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :ensure_email_confirmed
  before_action :ensure_profile_completed

  private

  def ensure_email_confirmed
    if user_signed_in? && !current_user.confirmed?
      redirect_to email_verification_path(email: current_user.email)
    end
  end

  def ensure_profile_completed
    if user_signed_in? && current_user.profile && !current_user.profile.profile_completed?
      # Modal will show automatically, but you can also redirect
      # redirect_to complete_profile_path
    end
  end
end
```

### Step 4: Best Practices

#### 4.1 Security Considerations

- **OTP Expiration**: Codes should expire (10 minutes recommended)
- **Rate Limiting**: Limit resend requests to prevent abuse
- **Code Generation**: Use cryptographically secure random generation
- **Validation**: Validate codes server-side, never trust client-side

#### 4.2 User Experience

- **Clear Instructions**: Provide clear guidance at each step
- **Progress Indication**: Show progress through multi-step forms
- **Error Handling**: Provide helpful error messages
- **Accessibility**: Ensure forms are keyboard navigable
- **Mobile Responsive**: Design for mobile and desktop

#### 4.3 Performance

- **Async Email**: Send emails asynchronously (ActiveJob)
- **Lazy Loading**: Load modal content only when needed
- **Caching**: Cache profile completion status
- **Database Indexes**: Index frequently queried fields

#### 4.4 Testing

```ruby
# spec/models/user_spec.rb
describe "#confirm_by_code!" do
  it "confirms user with valid code" do
    user = create(:user, confirmation_code: "123456")
    expect(user.confirm_by_code!("123456")).to be_truthy
    expect(user.confirmed_at).to be_present
  end

  it "rejects expired code" do
    user = create(:user, 
                  confirmation_code: "123456",
                  confirmation_code_sent_at: 11.minutes.ago)
    expect(user.confirm_by_code!("123456")).to be_falsey
  end
end

# spec/models/profile_spec.rb
describe "#profile_completed?" do
  it "returns false if not onboarded" do
    profile = create(:profile, onboarded: false)
    expect(profile.profile_completed?).to be_falsey
  end

  it "returns true when all required fields present" do
    profile = create(:profile, 
                     onboarded: true,
                     first_name: "John",
                     last_name: "Doe")
    expect(profile.profile_completed?).to be_truthy
  end
end
```

---

## Summary

The onboarding flow consists of:

1. **Email Verification**: 6-digit OTP system with 10-minute expiration
2. **Profile Onboarding**: 3-step modal form collecting user information
3. **Completion Tracking**: Boolean flags and validation methods
4. **User Experience**: Automatic modal display, progress tracking, real-time validation

Key technologies used:
- **Rails 7** with Devise for authentication
- **Stimulus** for JavaScript interactivity
- **Turbo Streams** for dynamic updates
- **ActiveJob** for async email delivery
- **ActiveStorage** for file uploads

This architecture provides a secure, user-friendly onboarding experience that can be adapted to various application needs.

