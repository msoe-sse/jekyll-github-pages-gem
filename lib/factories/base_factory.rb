# frozen_string_literal: true

require 'kramdown'

module Factories
  ##
  # The base class for all jekyll factories
  class BaseFactory
    def create_file_path_for_item(title, collection_name)
      formatted_collection_name = collection_name.lower
      file_name = "#{title.gsub(/\s+/, '')}.md"
      return "_#{collection_name}/#{file_name}" if collection_name
      file_name
    end
    
    def create_jekyll_item(page_contents, github_ref, pull_request_url)
      raise NotImplementedError 'create_jekyll_item is not implemented on this Factory'
    end

    protected

    def fix_header_syntax(text)
      document = Kramdown::Document.new(text)
      header_elements = document.root.children.select { |x| x.type == :header }
      lines = text.split("\n")
      lines = lines.map do |line|
        if header_elements.any? { |x| line.include? x.options[:raw_text] }
          # This regex matches the line into 2 groups with the first group being the repeating #
          # characters and the beginning of the string and the second group being the rest of the string
          line_match = line.match(/(#*)(.*)/)
          line = "#{line_match.captures.first} #{line_match.captures.last.strip}"
        else
          line.delete("\r\n")
        end
      end
      lines.join("\r\n")
    end

    def add_line_break_to_markdown_if_necessary(markdown)
      lines = markdown.split("\n")
      # The regular expression in the if statement looks for a markdown reference to a link like
      # [logo]: https://ieeextreme.org/wp-content/uploads/2019/05/Xtreme_colour-e1557478323964.png
      # If a post starts with that reference in jekyll followed by an image using that reference
      # the line below will be interperted as a paragraph tag instead of an image tag. To fix that
      # we add a line break to the start of the markdown.
      return "\r\n#{markdown}" if lines.first&.match?(/\[(.*)\]: (.*)/)

      markdown
    end
  end
end
