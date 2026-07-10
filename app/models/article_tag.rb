class ArticleTag < ApplicationRecord
  belongs_to :article
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :article_id }

  # NOTE: after_save_commit + after_destroy_commit both targeting the same
  # method name clobber each other in Rails' commit callback chain (the
  # second registration's :on condition silently replaces the first's,
  # since both share filter=:resync_article_search_entry/kind=:after) — the
  # save-side hook never fired. A single after_commit with no :on filter
  # covers create, update, and destroy correctly.
  after_commit :resync_article_search_entry

  private

  def resync_article_search_entry
    # Skip when the parent article was destroyed in the same transaction
    # (dependent: :destroy on Article#article_tags) — Article's own
    # remove_search_entry already ran; recreating the entry here would
    # leave a stale row pointing at a deleted article.
    return if article.destroyed?

    article.sync_search_entry
  end
end
