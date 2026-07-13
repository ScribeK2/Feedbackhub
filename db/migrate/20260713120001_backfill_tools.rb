class BackfillTools < ActiveRecord::Migration[8.1]
  def up
    Tool.reset_column_information
    Tool.seed_defaults!
  end

  def down
    Tool.where(url: Tool::DEFAULTS.map { |t| t[:url] }).delete_all
  end
end
