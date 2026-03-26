class CreateFeedbackTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :feedback_templates do |t|
      t.string :name, null: false
      t.json :field_schema, null: false, default: []

      t.timestamps
    end
    add_index :feedback_templates, :name, unique: true
  end
end
