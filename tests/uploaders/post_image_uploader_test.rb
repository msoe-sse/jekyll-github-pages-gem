# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../test_helper'
require_relative '../../lib/uploaders/post_image_uploader'


class PostImageUploaderTest < BaseGemTest
  def test_PostImageUploader_PostImageUploader_should_only_support_images    # Arrange
    uploader = PostImageUploader.new

    # Act
    result = uploader.extension_whitelist

    # Assert
    assert_equal ['jpg', 'jpeg', 'gif', 'png'], result
  end

  def test_PostImageUploader_PostImageUploader_should_limit_files_to_an_appropriate_size
     # Arrange
    uploader = PostImageUploader.new
    expected_range_in_megabytes = (1..5).step { |x| x * (1024 * 1024) }

    # Act
    result = uploader.size_range

    # Assert
    assert_equal expected_range_in_megabytes, result
  end
end
