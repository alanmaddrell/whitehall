require 'test_helper'

class AssetRemoverTest < ActiveSupport::TestCase
  setup do
    @logo_dir = File.join(Whitehall.clean_uploads_root, 'system', 'uploads', 'topical_event', 'logo')
    @logo_path = File.join(@logo_dir, '960x640_jpeg.jpg')
    fixture_asset_path = Rails.root.join('test', 'fixtures', 'images', '960x640_jpeg.jpg')

    FileUtils.mkdir_p(@logo_dir)
    FileUtils.cp(fixture_asset_path, @logo_path)

    @subject = AssetRemover.new
  end

  teardown do
    FileUtils.remove_dir(@logo_dir, true)
  end

  test '#remove_topical_event_logo removes all logos' do
    assert File.exist?(@logo_path)

    @subject.remove_topical_event_logo

    refute File.exist?(@logo_path)
  end

  test '#remove_topical_event_logo removes the containing directory' do
    assert Dir.exist?(@logo_dir)

    @subject.remove_topical_event_logo

    refute Dir.exist?(@logo_dir)
  end

  test '#remove_topical_event_logo returns an array of the files remaining after removal' do
    files = @subject.remove_topical_event_logo

    assert_equal [], files
  end
end
