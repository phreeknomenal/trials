# Turning on Devise's lockable. The ten character floor raised in this same
# change is a defence against guessing a password offline; this is the defence
# against guessing one against the live form, which the app had nothing for.
#
# unlock_token is unique and indexed because Devise looks an account up by it
# when someone follows the unlock link.
class AddLockableToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.integer :failed_attempts, default: 0, null: false
      t.string :unlock_token
      t.datetime :locked_at
    end

    add_index :users, :unlock_token, unique: true
  end
end
