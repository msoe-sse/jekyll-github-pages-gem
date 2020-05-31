# frozen_string_literal: true

require_relative '../test_helper'

# test the post image manager model
class PostImageManagerTest < BaseGemTest
  def setup
    # setup_clear_mocks
    PostImageManager.instance.clear
  end

  def test_add_file_should_create_a_new_post_image_uploader_and_cache_the_file
    # Arrange
    mock_file = create_mock_action_dispatch_file('my file.jpg')
    PostImageUploader.any_instance.expects(:cache!).with(mock_file).once

    # Act
    PostImageManager.instance.add_file(mock_file)

    # Assert
    assert_equal 1, PostImageManager.instance.uploaders.length
    assert PostImageManager.instance.uploaders.first.is_a?(PostImageUploader)
  end

  def test_add_file_should_remove_any_previous_uploaders_that_have_the_same_filename_as_the_file_being_added
    # Arrange
    mock_file = create_mock_action_dispatch_file('my file.jpg')
    PostImageUploader.any_instance.expects(:cache!).with(mock_file).twice
    PostImageUploader.any_instance.expects(:filename).returns('my file.jpg').at_least_once

    # Act
    PostImageManager.instance.add_file(mock_file)
    PostImageManager.instance.add_file(mock_file)

    # Assert
    assert_equal 1, PostImageManager.instance.uploaders.length
    assert PostImageManager.instance.uploaders.first.is_a?(PostImageUploader)
  end

  def test_add_downloaded_image_should_add_a_downloaded_image_to_the_donwloaded_images_collection
    # Arrange
    post_image = PostImage.new
    post_image.filename = 'Sample.jpg'
    post_image.contents = 'contents'

    # Act
    PostImageManager.instance.add_downloaded_image(post_image)

    # Assert
    assert_equal 1, PostImageManager.instance.downloaded_images.length
    assert PostImageManager.instance.downloaded_images.first.is_a?(PostImage)
  end

  def test_clear_should_clear_all_post_image_uploader_instances_from_the_manager
    # Arrange
    mock_file = create_mock_action_dispatch_file('my file.jpg')

    PostImageUploader.any_instance.expects(:cache!).with(mock_file).once

    # Act
    PostImageManager.instance.add_file(mock_file)
    PostImageManager.instance.clear

    # Assert
    assert_equal 0, PostImageManager.instance.uploaders.length
  end

  def test_clear_should_clear_all_postimage_instances_from_the_manager
    # Arrange
    post_image = PostImage.new
    post_image.filename = 'Sample.jpg'
    post_image.contents = 'contents'

    # Act
    PostImageManager.instance.add_downloaded_image(post_image)
    PostImageManager.instance.clear

    # Assert
    assert_equal 0, PostImageManager.instance.downloaded_images.length
  end

  private

  def setup_clear_mocks
    mock_uploader = create_mock_uploader('preview_my file.jpg', 'my cache/preview_my file.jpg', nil)
    preview_uploader = create_preview_uploader('my file', mock_uploader)

    PostImageUploader.any_instance.expects(:preview).returns(preview_uploader).at_least(0)
    PostImageUploader.any_instance.expects(:remove!).at_least(0)
    Dir.expects(:delete).with(any_paremeters).returns(nil).at_least(0)
  end
end
