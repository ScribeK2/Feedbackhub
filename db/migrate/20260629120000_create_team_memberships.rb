class CreateTeamMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :team_memberships do |t|
      t.references :manager, null: false, foreign_key: { to_table: :users }
      t.string :csr_name, null: false
      t.timestamps
    end
    add_index :team_memberships, [:manager_id, :csr_name], unique: true
  end
end
