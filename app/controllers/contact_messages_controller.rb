# The contact form.
#
# It stores the message and shows a confirmation. It does not email anyone,
# because the app cannot: production has `smtp_settings` commented out and no
# environment sets a delivery method, so a mailer here would raise or silently
# drop every message while the page said "sent". The page says what really
# happens instead, and admin reads the table.
class ContactMessagesController < ApplicationController
  # A visitor deciding whether to trust the app is exactly the person most
  # likely to want to ask something first. Same reasoning as PagesController.
  skip_before_action :ensure_profile_completed

  HOURLY_LIMIT = 5

  # Public and unauthenticated, so the only thing between it and a flood is a
  # limit. Five an hour is well above any real use and low enough that the table
  # cannot be filled from one address.
  rate_limit to: HOURLY_LIMIT, within: 1.hour,
    by: -> { request.remote_ip },
    with: -> { reject_rate_limited }

  def new
    @contact_message = ContactMessage.new(prefill)
  end

  def create
    @contact_message = ContactMessage.new(contact_message_params)

    # A bot fills every field it can see, including the one positioned off
    # screen. Dropping it silently rather than showing an error is deliberate:
    # an error tells the bot's author which field to leave alone next time.
    return render :confirmation, status: :created if honeypot_filled?

    if @contact_message.save
      render :confirmation, status: :created
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_message_params
    params.require(:contact_message).permit(:name, :email, :topic, :body)
  end

  # Saves a signed-in person typing what the app already knows. Nothing is
  # inferred for a signed-out visitor.
  def prefill
    return {} unless user_signed_in?

    {email: current_user.email, name: current_profile&.first_name}.compact_blank
  end

  def honeypot_filled?
    params[:contact_message]&.dig(:website).present?
  end

  def reject_rate_limited
    redirect_to contact_path,
      alert: "That is several messages in a short time. Try again in an hour, " \
             "or write to us directly at the address on this page."
  end
end
