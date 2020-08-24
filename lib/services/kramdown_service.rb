# frozen_string_literal: true

require 'kramdown'

##
# This modules contains extentions of the Kramdown::Convert module for custom kramdown converters
module Kramdown
  module Converter
    ##
    # A custom kramdown HTML converter for getting the HTML preview for a post
    class Preview < Html
      ##
      # An override of the convert_img tag which converts all image sources to pull
      # from the CarrierWare cache location if an uploader exists with the image's filename.
      # Or the Base64 contents of a downloaded image are replaced in the src attribute if the image
      # was downloaded for the post
      #
      # Params:
      # +el+::the image element to convert to html
      # +indent+::the indent of the HTML
      def convert_img(element, indent)
        formatted_filename = File.basename(element.attr['src']).tr(' ', '_')
        uploader = PostImageManager.instance.uploaders.find { |x| x.filename == formatted_filename }
        if uploader
          element.attr['src'] = "/uploads/tmp/#{uploader.preview.cache_name}"
        else
          downloaded_image = PostImageManager.instance.downloaded_images
                                             .find { |x| File.basename(x.filename) == File.basename(element.attr['src']) }
          if downloaded_image
            extension = File.extname(downloaded_image.filename)
            extension[0] = ''
            element.attr['src'] = "data:image/#{extension};base64,#{downloaded_image.contents}"
          end
        end

        super(element, indent)
      end
    end
  end
end

module Services
  ##
  # This class contains operations related to the kramdown engine
  class KramdownService
    DEFAULT_HERO = 'https://source.unsplash.com/collection/145103/'
    ##
    # This method takes given markdown and converts it to HTML for the post preview
    #
    # Params:
    # +text+:: markdown to convert to html
    def get_preview(text)
      Kramdown::Document.new(text).to_preview
    end

    ##
    # This method returns the image filename given some markdown
    #
    # Params:
    # +image_file_name+:: a filename of a image to look for in markdown
    # +markdown+:: text of a markdown post
    def get_image_filename_from_markdown(image_file_name, markdown)
      document = Kramdown::Document.new(markdown)
      document_descendants = []

      get_document_descendants(document.root, document_descendants)
      all_img_tags = document_descendants.select { |x| x.type == :img }
      matching_image_tag = all_img_tags.find { |x| get_filename_for_image_tag(x).tr(' ', '_') == image_file_name }

      return get_filename_for_image_tag(matching_image_tag) if matching_image_tag

      nil
    end

    ##
    # This method returns an array of all image paths given some markdown
    #
    # Params:
    # +markdown+:: text of a markdown post
    def get_all_image_paths(markdown)
      document = Kramdown::Document.new(markdown)
      document_descendants = []

      get_document_descendants(document.root, document_descendants)
      all_img_tags = document_descendants.select { |x| x.type == :img }

      result = all_img_tags.map do |img_tag|
        img_tag.attr['src'][1..-1] if img_tag.attr['src'] !~ URI::DEFAULT_PARSER.make_regexp
      end

      result.compact
    end

    private

    def get_document_descendants(current_element, result)
      current_element.children.each do |element|
        result << element
        get_document_descendants(element, result)
      end
    end

    def get_filename_for_image_tag(image_el)
      File.basename(image_el.attr['src'])
    end
  end
end
