# frozen_string_literal: true

require 'kramdown'

module Factories
  ##
  # The base class for all jekyll factories
  class BaseFactory
    ##
    # The default implementation of create_file_path_for_item which will format the file path for a given item.
    # The defaul implementation will use the title for the filename
    #
    # Params
    # +title+:: the title of the jekyll item
    # +collection_name+:: the name of the collection the item is in, defaults to nil
    def create_file_path_for_item(title, collection_name = nil)
      file_name = "#{title.gsub(/\s+/, '')}.md"
      return "#{collection_name.downcase}/#{file_name}" if collection_name

      file_name
    end

    ##
    # The default create_jekyll_item implementation. In order for this method to be called
    # it must be defined and implemented in subclasses
    #
    # Params
    # +item_contents+::markdown in a given item
    # +file_path+::the path on GitHub to the item
    # +github_ref+::a sha for a ref indicating the head of a branch a item is pushed to on the GitHub server
    def create_jekyll_item(_item_contents, _file_path, _github_ref, _pull_request_url)
      raise NotImplementedError
    end

    #
    # The default create_jekyll_item_text implementation. In order for this method to be called
    # it must be defined and implemented in subclasses
    #
    # Params
    # +properties+: A hash of all of the properties for the given item
    def create_jekyll_item_text(_properties)
      raise NotImplementedError
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
