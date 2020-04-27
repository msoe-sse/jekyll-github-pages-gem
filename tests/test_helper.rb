# frozen_string_literal: true

require 'simplecov'
SimpleCov.start
require_relative '../lib/models/post'

# This class sets up helper utilities used by gem tests
class BaseGemTest < MiniTest::Test
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

  def create_file_info_hash(file_path, blob_sha)
    { path: file_path, blob_sha: blob_sha }
  end

  def mock_image_blob_and_return_sha(mock_uploader)
    mock_ruby_file = create_mock_ruby_file(mock_uploader.filename)
    # The yields in this mock will execute the ruby block for File.open
    File.expects(:open).with(mock_uploader.post_image.file.file, 'rb')
        .returns(mock_ruby_file).yields(mock_ruby_file)
    Base64.expects(:encode64).with("File Contents for #{mock_uploader.filename}")
          .returns("base 64 for #{mock_uploader.filename}")

    sha_to_return = "blob sha for #{mock_uploader.filename}"
    Services::GithubService.any_instance.expects(:create_base64_encoded_blob)
                           .with("base 64 for #{mock_uploader.filename}")
                           .returns(sha_to_return)

    sha_to_return
  end
end
