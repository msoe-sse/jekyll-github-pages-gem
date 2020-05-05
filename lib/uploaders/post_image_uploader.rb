# frozen_string_literal: true
require 'carrierwave'
##
# The file uploader class for uploading images to a Jekyll website post
class PostImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  # These constants represent the maximum width and height an uploaded can be for the post preview
  # and for actually appearing on a Jekyll website. These numbers were initially determined by testing
  # with a 1920x1080 image. If you find a reason to change these numbers please document the reason
  # below
  PREVIEW_LIMIT = [800, 800].freeze
  POST_LIMIT = [800, 700].freeze

  storage :file

  ##
  # Limits only images to be uploaded to an SSE website post
  def extension_whitelist
    %w[jpg jpeg gif png]
  end

  def size_range
    # 5 mb is a very large photo it will probably never be reached. But
    # this will prevent people from passing off very large files as an image.
    # If you change this limit please document the reason for changing it below
    (1..5).step { |x| bytes_to_megabytes x }
  end

  version :preview do
    process resize_to_limit: PREVIEW_LIMIT
  end

  version :post_image do
    process resize_to_limit: POST_LIMIT
  end

  private
  def bytes_to_megabytes(bytes)
    bytes * (1024.0 * 1024.0)
  end
end
