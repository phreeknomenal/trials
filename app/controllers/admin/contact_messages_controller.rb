module Admin
  # Where the contact form actually goes. Without this the form would be a
  # write-only table, which is no better than a mailer that sends nowhere.
  class ContactMessagesController < BaseController
    include Paginatable

    def index
      authorize :admin, :access?

      @pagy, @contact_messages = pagy(scope, limit: page_size)
      @unanswered_count = ContactMessage.unanswered.count
    end

    # Marking one answered is the whole workflow: it moves off the top of the
    # list. The reply itself happens in whatever mail client the person actually
    # uses, because there is nothing here to send from.
    def update
      authorize :admin, :access?

      message = ContactMessage.find(params[:id])
      message.update!(answered_at: message.answered? ? nil : Time.current)

      redirect_to admin_contact_messages_path(filter: params[:filter]),
        notice: message.answered? ? "Marked answered." : "Moved back to unanswered."
    end

    private

    def scope
      return ContactMessage.unanswered.order(created_at: :desc) if params[:filter] == "unanswered"

      ContactMessage.for_admin
    end

    def default_page_size
      25
    end
  end
end
