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
    def create_page(page_contents, github_ref)
      create_page_model(page_contents, github_ref) if !page_contents.nil? && page_contents.is_a?(String)
    end
      
    private
        
    def create_page_model(page_contents, github_ref)
      result = Page.new
      
      result.github_ref = github_ref

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
      page_model.permalink = header.match(/title:\s*(.*)(\r\n|\r|\n)/).captures.first
    end
  end
end
