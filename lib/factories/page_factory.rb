# frozen_string_literal: true

require_relative '../models/page'

module Factories
  ##
  # This class is a factory for parsing page text and creating a correseponding page model
  class PageFactory < BaseFactory
    ##
    # This method parses markdown in a page a returns a page model
    #
    # Params:
    # +page_contents+::markdown in a given page
    # +github_ref+::a sha for a ref indicating the head of a branch a page is pushed to on the GitHub server
    # +pull_request_url+::a url to the pull request with the branch the pull request is pushed to on the GitHub server
    def create_page(page_contents, github_ref, pull_request_url)
      create_page_model(page_contents, github_ref, pull_request_url) if !page_contents.nil? && page_contents.is_a?(String)
    end

    ##
    # This method takes parameters for a given page and formats them
    # as a valid page for a Jekyll website
    #
    # Params:
    # +text+:: the required markdown contents of the post
    # +title+:: the required title of the post
    # +permalink+:: the link to the page on a Jekyll website (e.g /about)
    def create_jekyll_page_text(text, title, permalink)
      header_converted_text = fix_header_syntax(text)
      header_converted_text = add_line_break_to_markdown_if_necessary(header_converted_text)

      %(---
layout: page
title: #{title}
permalink: #{permalink}
---
#{header_converted_text})
    end

    private

    def create_page_model(page_contents, github_ref, pull_request_url)
      result = Page.new

      result.github_ref = github_ref
      result.pull_request_url = pull_request_url

      # What this regular expression does is it matches three groups
      # The first group represents the header of the page which appears
      # between the two --- lines. The second group is for helping capture newline characters
      # correctly and the third group is the actual page contents
      match_obj = page_contents.match(/---(.*)---(\r\n|\r|\n)(.*)/m)
      header = match_obj.captures[0]
      parse_page_header(header, result)
      result.contents = match_obj.captures[2]

      result
    end

    def parse_page_header(header, page_model)
      # The following regular expressions in this method look for specific properities
      # located in the post header.
      page_model.title = header.match(/title:\s*(.*)(\r\n|\r|\n)/).captures.first
      page_model.permalink = header.match(/permalink:\s*(.*)(\r\n|\r|\n)/).captures.first
    end
  end
end
