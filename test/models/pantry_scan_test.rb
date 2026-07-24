require "base64"
require "test_helper"

class PantryScanTest < ActiveSupport::TestCase
  PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4////fwAJ+wP9KobjigAAAABJRU5ErkJggg=="

  def setup
    @scan = PantryScan.new(user: users(:one), label: "Frigo")
  end

  test "scan valide avec une photo" do
    @scan.photos.attach(valid_image_attachment)

    assert @scan.valid?, @scan.errors.full_messages.to_sentence
  end

  test "scan invalide sans photo" do
    assert_not @scan.valid?
    assert_includes @scan.errors[:photos], "doit être attaché"
  end

  test "scan invalide avec plus de cinq photos" do
    6.times { @scan.photos.attach(valid_image_attachment) }

    assert_not @scan.valid?
    assert_includes @scan.errors[:photos], "doivent contenir entre 1 et 5 images"
  end

  test "scan invalide avec un fichier non image" do
    @scan.photos.attach(
      io: StringIO.new("not an image"),
      filename: "notes.txt",
      content_type: "text/plain"
    )

    assert_not @scan.valid?
    assert_includes @scan.errors[:photos], "doivent être au format JPG, PNG ou WebP"
  end

  test "scan invalide avec un format image non autorise" do
    @scan.photos.attach(
      io: StringIO.new("<svg xmlns='http://www.w3.org/2000/svg'></svg>"),
      filename: "frigo.svg",
      content_type: "image/svg+xml"
    )

    assert_not @scan.valid?
    assert_includes @scan.errors[:photos], "doivent être au format JPG, PNG ou WebP"
  end

  test "scan invalide avec une image trop volumineuse" do
    @scan.photos.attach(image_attachment(PantryScan::MAX_PHOTO_SIZE + 1))

    assert_not @scan.valid?
    assert_includes @scan.errors[:photos], "doivent peser 8 Mo maximum chacune"
  end

  test "scan invalide quand le poids cumule depasse la limite" do
    photo_size = (PantryScan::MAX_TOTAL_PHOTOS_SIZE / PantryScan::MAX_PHOTOS) + 1
    PantryScan::MAX_PHOTOS.times { @scan.photos.attach(image_attachment(photo_size)) }

    assert_not @scan.valid?
    assert_includes @scan.errors[:photos], "ne doivent pas dépasser 20 Mo au total"
  end

  private

  def valid_image_attachment
    image_attachment(Base64.decode64(PNG_BASE64).bytesize)
  end

  def image_attachment(size)
    png = Base64.decode64(PNG_BASE64)
    content = png.ljust(size, "\0")

    {
      io: StringIO.new(content),
      filename: "frigo.png",
      content_type: "image/png"
    }
  end
end
