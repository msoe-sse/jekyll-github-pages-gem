# frozen_string_literal: true

module Factories
  ##
  # This class is a factory for parsing post text and creating a correseponding post model
  class PostFactory < BaseFactory
    LEAD = '{: .lead}'
    BREAK = '<!–-break-–>'

    # serves as the default hero for a post if none is provided.
    DEFAULT_HERO = 'https://source.unsplash.com/collection/145103/'

    ##
    # A redefinition of the create_file_path_for_item method. This will make sure that
    # the current date is added on to post file names
    #
    # Params
    # +title+:: the title of the jekyll item
    # +collection_name+:: the name of the collection the item is in, defaults to nil
    def create_file_path_for_item(title, collection_name = nil)
      file_name = "#{DateTime.now.strftime('%Y-%m-%d')}-#{title.gsub(/\s+/, '')}.md"
      return "#{collection_name.downcase}/#{file_name}" if collection_name

      file_name
    end

    ##
    # This method parses markdown in a post a returns a post model
    #
    # Params:
    # +item_contents+::markdown in a given post
    # +file_path+::the path on GitHub to the post
    # +pull_request_url+::a url to the pull request with the branch the pull request is pushed to on the GitHub server
    def create_jekyll_item(item_contents, file_path, pull_request_url)
      create_post_model(item_contents, file_path, pull_request_url) if !item_contents.nil? && item_contents.is_a?(String)
    end

    ##
    # This method takes parameters for a given post and formats them
    # as a valid post for a Jekyll website
    #
    # Params:
    # +text+:: the required markdown contents of the post
    # +author+:: the required author of the post
    # +title+:: the required title of the post
    # +tags+:: optional tags specific to the post, defaults to nil
    # +overlay+:: the optional overlay color of the post, defaults to nil
    # +hero+:: a link to an optional background image for a post, defaults to nil
    # +set_published_property+::an optional flag to set the published: true property for a post, defaults to false
    # +append_lead_break_section+::an optional flag indicating whether to append to lead break section to a post, default to false
    def create_jekyll_post_text(text, author, title, tags = nil, overlay = nil,
                                hero = nil, set_published_property = false, append_lead_break_section = false)
      header_converted_text = fix_header_syntax(text)
      header_converted_text = add_line_break_to_markdown_if_necessary(header_converted_text)

      parsed_tags = nil
      parsed_tags = format_tags(tags) if tags

      tag_section = %(tags:
#{parsed_tags})

      lead_break_section = "{: .lead}\r\n<!–-break-–>"

      hero_to_use = hero
      hero_to_use = DEFAULT_HERO if hero_to_use&.empty?
      result = %(---
layout: post
title: #{title}
author: #{author}\r\n)

      result += "#{tag_section}\r\n" unless !parsed_tags || parsed_tags.empty?
      result += "hero: #{hero_to_use}\n" if hero_to_use
      result += "overlay: #{overlay}\n" if overlay
      result += "published: true\n" if set_published_property
      result += "---\n"
      result += "#{lead_break_section}\n" if append_lead_break_section
      result += header_converted_text

      result
    end

    private

    def parse_tags(header)
      result = []
      header.lines.each do |line|
        tag_match = line.match(/\s*-\s*(.*)/)
        result << tag_match.captures.first if tag_match
      end
      result.join(', ')
    end

    def format_tags(tags)
      tag_array = tags.split(',')
      result = ''
      tag_array.each do |tag|
        result += "  - #{tag.strip}"
        result += "\r\n" if tag != tag_array.last
      end
      result
    end

    def create_post_model(post_contents, file_path, pull_request_url)
      result = Post.new

      result.file_path = file_path
      result.pull_request_url = pull_request_url

      # What this regular expression does is it matches three groups
      # The first group represents the header of the post which appears
      # between the two --- lines. The second group is for helping capture newline characters
      # correctly and the third group is the actual post contents
      match_obj = post_contents.match(/---(.*)---(\r\n|\r|\n)(.*)/m)
      header = match_obj.captures[0]

      parse_post_header(header, result)
      result.contents = match_obj.captures[2]
                                 .gsub("#{LEAD}\r\n", '')
                                 .gsub("#{LEAD}\n", '')
                                 .gsub("#{BREAK}\r\n", '')
                                 .gsub("#{BREAK}\n", '')
      result.tags = parse_tags(header)
      result
    end

    def parse_post_header(header, post_model)
      # The following regular expressions in this method look for specific properities
      # located in the post header.
      post_model.title = header.match(/title:\s*(.*)(\r\n|\r|\n)/).captures.first
      post_model.author = header.match(/author:\s*(.*)(\r\n|\r|\n)/).captures.first
      post_model.hero = header.match(/hero:\s*(.*)(\r\n|\r|\n)/).captures.first
      post_model.hero = '' if post_model.hero == DEFAULT_HERO
      post_model.overlay = header.match(/overlay:\s*(.*)(\r\n|\r|\n)/).captures.first
    end
  end
end
