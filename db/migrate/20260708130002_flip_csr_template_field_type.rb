# frozen_string_literal: true

class FlipCsrTemplateFieldType < ActiveRecord::Migration[8.1]
  class MigrationTemplate < ActiveRecord::Base
    self.table_name = "feedback_templates"
  end

  def up
    flip("string", "csr")
  end

  def down
    flip("csr", "string")
  end

  private

  def flip(from, to)
    MigrationTemplate.find_each do |template|
      schema = template.field_schema
      changed = false
      schema.each do |field|
        next unless field["name"] == "csr" && field["type"] == from

        field["type"] = to
        changed = true
      end
      template.update_columns(field_schema: schema) if changed
    end
  end
end
