# frozen_string_literal: true

require_relative '../test_helper'

# tests the kramdown service
class KramdownServiceTest < BaseGemTest
  def setup
    @kramdown_service = Services::KramdownService.new
  end

  def test_get_preview_should_convert_markdown_to_html
    # Arrange
    markdown = %(#Andy is cool Andy is nice)

    # Act
    result = @kramdown_service.get_preview(markdown)

    # Assert
    assert !result.nil?
  end

  def test_get_preview_shouldnt_update_src_attr_of_img_tags_if_no_uploader_or_post_img_exists_in_post_img_mgr
    # Arrange
    mock_uploader = create_mock_uploader('preview_no image.png', 'my cache', nil)
    preview_uploader = create_preview_uploader('no image.png', mock_uploader)
    post_image = create_post_image('no image2.png', 'contents')

    PostImageManager.instance.expects(:uploaders).returns([preview_uploader])
    PostImageManager.instance.expects(:downloaded_images).returns([post_image])

    markdown = '![20170610130401_1.jpg](/assets/img/20170610130401_1.jpg)'

    # Act
    result = @kramdown_service.get_preview(markdown)

    # Assert
    assert_equal "<p><img src=\"/assets/img/20170610130401_1.jpg\" alt=\"20170610130401_1.jpg\" /></p>\n", result
  end

  def test_get_preview_should_update_the_src_attribute_of_img_tags_if_an_uploader_exists_in_postimagemanager
    # Arrange
    mock_uploader = create_mock_uploader('preview_20170610130401_1.jpg', 'my cache/preview_20170610130401_1.jpg', nil)
    preview_uploader = create_preview_uploader('20170610130401_1.jpg', mock_uploader)
    post_image = create_post_image('assets/img/20170610130401_1.jpg', 'contents')

    PostImageManager.instance.expects(:uploaders).returns([preview_uploader])
    PostImageManager.instance.expects(:downloaded_images).returns([post_image]).never

    markdown = '![My Alt Text](/assets/img/20170610130401_1.jpg)'
    expected_html = "<p><img src=\"/uploads/tmp/my cache/preview_20170610130401_1.jpg\" alt=\"My Alt Text\" /></p>\n"

    # Act
    result = @kramdown_service.get_preview(markdown)

    # Assert
    assert_equal expected_html, result
  end

  def test_get_preview_should_update_the_src_attribute_of_image_tags_if_a_postimage_exists_in_postimagemanager
    # Arrange
    post_image = create_post_image('assets/img/20170610130401_1.jpg', 'contents')
    markdown = '![My Alt Text](/assets/img/20170610130401_1.jpg)'
    expected_html = "<p><img src=\"data:image/jpg;base64,contents\" alt=\"My Alt Text\" /></p>\n"

    PostImageManager.instance.expects(:uploaders).returns([])
    PostImageManager.instance.expects(:downloaded_images).returns([post_image])

    # Act
    result = @kramdown_service.get_preview(markdown)

    # Assert
    assert_equal expected_html, result
  end

  # Test Case for Issue 22 on GitHub
  def test_get_preview_should_update_the_src_attribute_of_images_tags_if_uploader_with_formatted_filename_exists_in_post_image_manager
    # Arrange
    mock_uploader = create_mock_uploader('preview_My_File.jpg', 'my cache/preview_My_File.jpg', nil)
    preview_uploader = create_preview_uploader('My_File.jpg', mock_uploader)

    PostImageManager.instance.expects(:uploaders).returns([preview_uploader])

    markdown = '![My Alt Text](/assets/img/My File.jpg)'
    expected_html = "<p><img src=\"/uploads/tmp/my cache/preview_My_File.jpg\" alt=\"My Alt Text\" /></p>\n"

    # Act
    result = @kramdown_service.get_preview(markdown)

    # Assert
    assert_equal expected_html, result
  end

  def test_get_image_filename_from_markdown_should_return_nil_if_the_markdown_doesnt_include_img_with_a_given_filename
    # Arrange
    markdown = '![My Alt Text](/assets/img/20170610130401_1.jpg)'

    # Act
    result = @kramdown_service.get_image_filename_from_markdown('my file.jpg', markdown)

    # Assert
    assert_nil result
  end

  def test_get_image_filename_from_markdown_should_return_a_filename_if_the_markdown_does_include_an_imge_with_a_given_filename
    # Arrange
    markdown = '![My Alt Text](/assets/img/20170610130401_1.jpg)'

    # Act
    result = @kramdown_service.get_image_filename_from_markdown('20170610130401_1.jpg', markdown)

    # Assert
    assert_equal '20170610130401_1.jpg', result
  end

  # Test Case for Issue 22 on GitHub
  def test_get_image_filename_from_markdown_should_return_true_if_markdown_includes_an_img_with_given_filename_and_filename_formatted_by_carrierwave
    # Arrange
    markdown = '![My Alt Text](/assets/img/My File.jpg)'

    # Act
    result = @kramdown_service.get_image_filename_from_markdown('My_File.jpg', markdown)

    # Assert
    assert_equal 'My File.jpg', result
  end

  def test_get_all_image_paths_should_return_all_image_paths_given_some_markdown
    # Arrange
    markdown = "![My Alt Text](/assets/img/My File.jpg)\r\n![My Alt Text](/assets/img/My File2.jpg)"

    # Act
    result = @kramdown_service.get_all_image_paths(markdown)

    # Assert
    assert_equal 2, result.length
    assert_equal 'assets/img/My File.jpg', result[0]
    assert_equal 'assets/img/My File2.jpg', result[1]
  end

  def test_get_all_images_paths_should_not_return_image_paths_from__uris
    # Arrange
    markdown = '![My Alt Text](https://google.com/blah.jpg)'

    # Act
    result = @kramdown_service.get_all_image_paths(markdown)

    # Assert
    assert_equal 0, result.length
  end
end
