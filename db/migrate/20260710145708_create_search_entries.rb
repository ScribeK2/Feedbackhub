class CreateSearchEntries < ActiveRecord::Migration[8.1]
  def up
    create_table :search_entries do |t|
      t.string :parent_type, null: false
      t.integer :parent_id, null: false
      t.string :unit_type, null: false
      t.integer :unit_id, null: false
      t.text :content, null: false
      t.timestamps
    end
    add_index :search_entries, [ :unit_type, :unit_id ], unique: true
    add_index :search_entries, [ :parent_type, :parent_id ]

    execute <<~SQL
      CREATE VIRTUAL TABLE search_entries_fts USING fts5(
        content,
        content='search_entries',
        content_rowid='id',
        tokenize='porter unicode61'
      );
    SQL
    execute <<~SQL
      CREATE TRIGGER search_entries_ai AFTER INSERT ON search_entries BEGIN
        INSERT INTO search_entries_fts(rowid, content) VALUES (new.id, new.content);
      END;
    SQL
    execute <<~SQL
      CREATE TRIGGER search_entries_ad AFTER DELETE ON search_entries BEGIN
        INSERT INTO search_entries_fts(search_entries_fts, rowid, content) VALUES ('delete', old.id, old.content);
      END;
    SQL
    execute <<~SQL
      CREATE TRIGGER search_entries_au AFTER UPDATE ON search_entries BEGIN
        INSERT INTO search_entries_fts(search_entries_fts, rowid, content) VALUES ('delete', old.id, old.content);
        INSERT INTO search_entries_fts(rowid, content) VALUES (new.id, new.content);
      END;
    SQL
  end

  def down
    execute "DROP TRIGGER search_entries_au;"
    execute "DROP TRIGGER search_entries_ad;"
    execute "DROP TRIGGER search_entries_ai;"
    execute "DROP TABLE search_entries_fts;"
    drop_table :search_entries
  end
end
