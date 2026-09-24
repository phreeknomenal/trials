# The contact form has to land somewhere, and it cannot be an inbox: no
# environment has SMTP configured, so a mailer would report success and deliver
# nothing. It goes in a table that admin reads instead, which is true today and
# stays true after SMTP lands, when a notification becomes an addition rather
# than a replacement.
class CreateContactMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :contact_messages do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :topic, null: false
      t.text :body, null: false

      # Set when someone in admin marks it dealt with. Null means nobody has
      # looked at it, which is the only thing the admin list needs to sort on.
      t.datetime :answered_at

      t.timestamps
    end

    # The admin list is "unanswered first, newest first" and nothing else.
    add_index :contact_messages, [:answered_at, :created_at]
  end
end
