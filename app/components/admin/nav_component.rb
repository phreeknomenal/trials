module Admin
  # The admin bar, from the boards. All four of them draw the same one.
  #
  # It was an amber warning band with no mark on it, which read as a validation
  # message stuck to the top of the page rather than as chrome. The boards use a
  # dark navy bar carrying the mark, the wordmark and an ADMIN pill: still
  # unmistakably not the member-facing UI, which is the point the amber was
  # making, but saying so as an identity rather than as a warning.
  #
  # Dark in both themes, deliberately. The public app follows the reader's
  # theme; this bar is the same colour whichever they chose, so that admin never
  # looks like the app.
  class NavComponent < ApplicationComponent
    erb_template <<~ERB
      <nav class="bg-surface-on-dark border-b border-line-on-dark" aria-label="Admin">
        <div class="px-5 lg:px-12 py-3 flex items-center justify-between gap-6 flex-wrap">

          <%= link_to admin_root_path, class: "flex items-center gap-3 rounded-nav focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-on-dark" do %>
            <%= render Utilities::MarkComponent.new(height: 6, on_dark: true) %>
            <span class="font-primary text-lg font-extrabold tracking-tight text-ink-on-dark">Dira<span class="font-light text-ink-3-on-dark"> Health</span></span>
            <span class="rounded-full bg-line-on-dark px-2.5 py-1 text-[11px] font-bold tracking-[0.08em] text-ink-2-on-dark">ADMIN</span>
          <% end %>

          <div class="flex items-center gap-2 flex-wrap">
            <% links.each do |label, path| %>
              <%= link_to label, path,
                    aria: {current: current?(path) ? "page" : nil},
                    class: "px-3 py-1.5 rounded-nav text-sm font-semibold transition-colors \#{current?(path) ? "bg-navy-800 text-ink-2-on-dark" : "text-ink-3-on-dark hover:text-ink-on-dark"}" %>
            <% end %>

            <%# Also what gives admin a theme at all: the controller applies the
                dark class on connect, and no admin page mounted it, so admin
                ignored the reader's choice and rendered light whatever they had
                picked. PR 11 swept every page for dark and missed this one the
                same way the plan missed the admin bar. %>
            <%= render Buttons::DarkModeToggleComponent.new(on_dark: true) %>

            <span class="w-px h-5 bg-line-on-dark mx-1" aria-hidden="true"></span>

            <%# Kept, though the boards drop it. Knowing which account you are
                acting as matters more here than anywhere else in the app. %>
            <span class="text-xs text-ink-3-on-dark"><%= current_user.email %> &middot; <%= current_user.role %></span>

            <%= link_to "Back to app", root_path,
                  class: "text-sm font-semibold text-ink-3-on-dark hover:text-ink-on-dark transition-colors" %>
          </div>
        </div>
      </nav>
    ERB

    # Messages is not on the boards: admin/contact_messages did not exist when
    # they were drawn, and PR #147 added it.
    def links
      {
        "Dashboard" => admin_root_path,
        "Operations" => admin_operations_path,
        "Testimonials" => admin_testimonials_path,
        "Users" => admin_users_path,
        "Messages" => admin_contact_messages_path
      }
    end

    def current?(path)
      helpers.request.path == path
    end
  end
end
