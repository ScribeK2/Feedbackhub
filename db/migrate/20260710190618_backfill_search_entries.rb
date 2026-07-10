class BackfillSearchEntries < ActiveRecord::Migration[8.1]
  def up
    SearchEntry.rebuild!
  end

  def down
    SearchEntry.delete_all
  end
end
