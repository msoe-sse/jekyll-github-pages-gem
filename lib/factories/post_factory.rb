# frozen_string_literal: true

require_relative '../models/post'

module Factories
  ##
  # This class is a factory for parsing post text and creating a correseponding post model
  class PostFactory < BaseFactory
    LEAD = '{: .lead}'
    BREAK = '<!–-break-–>'

    # serves as the default hero for a post if none is provided.
    DEFAULT_HERO = 'https://source.unsplash.com/collection/145103/'

    ##
    # This method parses markdown in a post a returns a post model
    #
    # Params:
    # +post_contents+::markdown in a given post
    # +file_path+::the path on GitHub to the post
    # +ref+::a sha for a ref indicating the head of a branch a post is pushed to on the GitHub server
    def create_post(post_contents, file_path, ref)
      create_post_model(post_contents, file_path, ref) if !post_contents.nil? && post_contents.is_a?(String)
    end

    ##
    # This method takes parameters for a given post and formats them
    # as a valid jekyll post for a Jekyll website
    #
    # Params:
    # +text+:: the required markdown contents of the post
    # +author+:: the required author of the post
    # +title+:: the required title of the post
    # +tags+:: optional tags specific to the post
    # +overlay+:: the optional overlay color of the post
    # +hero+:: a link to an optional background image for a post
    def create_jekyll_post_text(text, author, title, tags = nil, overlay = nil, hero = nil, set_published_property = false, append_lead_break_section = false)
      header_converted_text = fix_header_syntax(text)
      header_converted_text = add_line_break_to_markdown_if_necessary(header_converted_text)
      
      parsed_tags = nil
      parsed_tags = format_tags(tags) unless !tags

      tag_section = %(tags:
#{parsed_tags})

      lead_break_section = "{: .lead}\r\n<!–-break-–>"

      hero_to_use = hero
      hero_to_use = DEFAULT_HERO if hero_to_use && hero_to_use.empty?
      result = %(---
layout: post
title: #{title}
author: #{author}\r\n)

      result += "#{tag_section}\r\n" unless !parsed_tags || parsed_tags.empty?
      result += "hero: #{hero_to_use}\n" unless !hero_to_use
      result += "overlay: #{overlay}\n" unless !overlay
      result += "published: true\n" unless !set_published_property
      result += "---\n"
      result += "#{lead_break_section}\n" unless !append_lead_break_section
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

    def create_post_model(post_contents, file_path, ref)
      result = Post.new

      result.file_path = file_path
      result.github_ref = ref

      # What this regular expression does is it matches three groups
      # The first group represents the header of the post which appears
      # between the two --- lines. The second group is for helping capture newline characters
      # correctly and the third group is the actual post contents
      match_obj = post_contents.match(/---(.*)---(\r\n|\r|\n)(.*)/m)
      header = match_obj.captures[0]

      parse_post_header(header, result)
      result.contents = match_obj.captures[2]
                                 .remove("#{LEAD}\r\n")
                                 .remove("#{LEAD}\n")
                                 .remove("#{BREAK}\r\n")
                                 .remove("#{BREAK}\n")
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
