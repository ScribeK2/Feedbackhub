require "test_helper"

class ActiveStorageVariantTest < ActiveSupport::TestCase
  test "image blobs process a resized variant via the vips backend" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename: "sample.png",
      content_type: "image/png"
    )

    assert blob.representable?, "PNG blob should be representable"

    # This is the exact call _blob.html.erb makes; it raises
    # LoadError: cannot load such file -- vips when no vips binding is bundled.
    variant = blob.representation(resize_to_limit: [ 100, 100 ]).processed

    # Rails 8 tracks variants (VariantWithRecord), so the processed variant
    # exposes its generated image blob.
    assert variant.image.blob.present?, "processed variant should have a blob"
    assert_equal "image/png", variant.image.blob.content_type
    assert variant.image.blob.byte_size.positive?
  ensure
    blob&.purge
  end
end
