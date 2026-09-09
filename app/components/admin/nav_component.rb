module Admin
  class NavComponent < ApplicationComponent
    erb_template <<~ERB
      <nav class="border-b border-warn/30 dark:border-warn-on-dark bg-warn/10 dark:bg-warn-on-dark/30">
        <div class="px-5 lg:px-12 py-3 flex items-center gap-6 flex-wrap">
          <span class="text-xs font-bold uppercase tracking-wider text-warn dark:text-warn-on-dark">Admin</span>

          <% links.each do |label, path| %>
            <%= link_to label, path,
                  class: "text-sm font-medium \#{current?(path) ? "text-warn dark:text-warn-on-dark underline underline-offset-4" : "text-ink-3 dark:text-ink-3-on-dark hover:text-ink dark:hover:text-ink-on-dark"}" %>
          <% end %>

          <div class="ml-auto flex items-center gap-4">
            <span class="text-xs text-ink-3 dark:text-ink-4-on-dark"><%= current_user.email %> &middot; <%= current_user.role %></span>
            <%= link_to "Back to site", root_path, class: "text-sm font-medium text-ink-3 dark:text-ink-3-on-dark hover:text-ink dark:hover:text-ink-on-dark" %>
          </div>
        </div>
      </nav>
    ERB

    def links
      {"Overview" => admin_root_path, "Operations" => admin_operations_path, "Users" => admin_users_path, "Testimonials" => admin_testimonials_path}
    end

    def current?(path)
      helpers.request.path == path
    end
  end
end
