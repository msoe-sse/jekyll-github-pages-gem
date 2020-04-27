# frozen_string_literal: true

require_relative '../lib/models/post'

# This class sets up helper utilities used by gem tests
class TestHelper < MiniTest::Test
  protected

  ## creates a mock image uploader
  class MockUploader
    attr_accessor :filename
    attr_accessor :cache_name
    attr_accessor :file
    attr_accessor :preview
    attr_accessor :post_image
  end

  ## creates a mock carrier wave
  class MockCarrierWaveFile
    attr_accessor :file # This actually represents the filepath which matches the carrierware file object
  end

  ## creates a mock ruby file
  class MockRubyFile
    attr_accessor :filename

    def read
      "File Contents for #{filename}"
    end
  end

  ## creates a mock action displatch file
  class MockActionDispatchFile
    attr_accessor :original_filename
  end

  ## creates a mock http object
  class MockHttp
    def initialize(content_type)
      @content_type = content_type
    end

    def head(_uri)
      { 'Content-Type' => @content_type }
    end
  end

  def create_mock_uploader(filename, cache_name, file)
    result = MockUploader.new
    result.filename = filename
    result.cache_name = cache_name
    result.file = file
    result
  end

  def create_preview_uploader(filename, preview)
    result = MockUploader.new
    result.filename = filename
    result.preview = preview
    result
  end

  def create_post_image_uploader(filename, post_image)
    result = MockUploader.new
    result.filename = filename
    result.post_image = post_image
    result
  end

  def create_mock_carrierware_file(file)
    result = MockCarrierWaveFile.new
    result.file = file
    result
  end

  def create_mock_ruby_file(filename)
    result = MockRubyFile.new
    result.filename = filename
    result
  end

  def create_mock_action_dispatch_file(filename)
    result = MockActionDispatchFile.new
    result.original_filename = filename
    result
  end

  def create_post_image(filename, contents)
    result = PostImage.new
    result.filename = filename
    result.contents = contents
    result
  end
end
