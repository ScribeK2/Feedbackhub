class MakeNotificationsPolymorphic < ActiveRecord::Migration[8.1]
  def up
    add_column :notifications, :event_type, :string
    add_column :notifications, :event_id, :integer
    execute "UPDATE notifications SET event_type = 'Comment', event_id = comment_id"
    change_column_null :notifications, :event_type, false
    change_column_null :notifications, :event_id, false
    # SQLite's remove_column table rebuild keeps multi-column indexes minus the
    # removed column (leaving a bogus unique index on user_id alone), so drop
    # indexes covering comment_id explicitly first.
    remove_index :notifications, [ :user_id, :comment_id ]
    remove_column :notifications, :comment_id
    add_index :notifications, [ :user_id, :event_type, :event_id ], unique: true
    add_index :notifications, [ :event_type, :event_id ]
  end

  def down
    add_column :notifications, :comment_id, :integer
    execute "DELETE FROM notifications WHERE event_type <> 'Comment'"
    execute "UPDATE notifications SET comment_id = event_id"
    change_column_null :notifications, :comment_id, false
    remove_index :notifications, [ :user_id, :event_type, :event_id ]
    remove_index :notifications, [ :event_type, :event_id ]
    remove_column :notifications, :event_type
    remove_column :notifications, :event_id
    add_foreign_key :notifications, :comments
    add_index :notifications, [ :user_id, :comment_id ], unique: true
  end
end
