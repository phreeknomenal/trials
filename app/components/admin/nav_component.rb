module Admin
  class NavComponent < ApplicationComponent
    erb_template <<~ERB
      <nav class="border-b border-amber-300 dark:border-amber-800 bg-amber-50 dark:bg-amber-950/30">
        <div class="px-5 lg:px-12 py-3 flex items-center gap-6 flex-wrap">
          <span class="text-xs font-bold uppercase tracking-wider text-amber-800 dark:text-amber-300">Admin</span>

          <% links.each do |label, path| %>
            <%= link_to label, path,
                  class: "text-sm font-medium \#{current?(path) ? "text-amber-900 dark:text-amber-200 underline underline-offset-4" : "text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-200"}" %>
          <% end %>

          <div class="ml-auto flex items-center gap-4">
            <span class="text-xs text-zinc-500 dark:text-zinc-500"><%= current_user.email %> &middot; <%= current_user.role %></span>
            <%= link_to "Back to site", root_path, class: "text-sm font-medium text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-200" %>
          </div>
        </div>
      </nav>
    ERB

    def links
      {"Overview" => admin_root_path, "Operations" => admin_operations_path, "Testimonials" => admin_testimonials_path}
    end

    def current?(path)
      helpers.request.path == path
    end
  end
end
