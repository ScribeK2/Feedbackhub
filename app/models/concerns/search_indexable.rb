# frozen_string_literal: true

# Keeps one SearchEntry row in sync per searchable unit. Including models
# implement:
#   search_parent  -> the record a search hit resolves to
#   search_content -> plain-text String (blank/nil means "no entry")
# Sync runs after commit so rich text saved inside the parent's transaction
# is visible to to_plain_text.
module SearchIndexable
  extend ActiveSupport::Concern

  included do
    after_save_commit :sync_search_entry
    after_destroy_commit :remove_search_entry
  end

  def sync_search_entry
    content = search_content
    if content.blank?
      remove_search_entry
      return
    end

    parent = search_parent
    entry = SearchEntry.find_or_initialize_by(unit_type: self.class.name, unit_id: id)
    entry.update!(parent_type: parent.class.name, parent_id: parent.id, content: content)
  end

  def remove_search_entry
    SearchEntry.where(unit_type: self.class.name, unit_id: id).delete_all
  end
end
