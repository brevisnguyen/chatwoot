class AddStateToUserSessions < ActiveRecord::Migration[7.1]
  def change
    add_column :user_sessions, :state, :string
  end
end
