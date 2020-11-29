# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/tests/'
end

require 'minitest/autorun'
require 'mocha/minitest'

require File.join(File.dirname(__FILE__), '../lib/jekyll_github_pages.rb')
require_relative '../lib/utilities/utilities'

# This class sets up helper utilities used by gem tests
class BaseGemTest < MiniTest::Test
  protected

  ## creates a mock http object
  class MockHttp
    def initialize(content_type)
      @content_type = content_type
    end

    def head(_uri)
      { 'Content-Type' => @content_type }
    end
  end

  def create_file_info_hash(file_path, blob_sha)
    { path: file_path, blob_sha: blob_sha }
  end

  def create_pull_request_file_hash(ref, filename, deleted = false)
    result = {
      contents_url: "http://example.com?ref=#{ref}",
      filename: filename
    }
    if deleted
      result[:added] = 0
      result[:deleted] = 1
    else
      result[:added] = 1
      result[:deleted] = 0
    end
    result
  end

  def create_pull_request_hash(username, body, number, pull_request_url = nil)
    {
      user: {
        login: username
      },
      body: body,
      number: number,
      html_url: pull_request_url
    }
  end

  def create_dummy_api_resource(parameters)
    resource = DummyApiResource.new
    resource.path = parameters[:path]
    resource.content = parameters[:content]
    resource
  end

  ##
  # Represents a dummy API resource object from Octokit
  class DummyApiResource
    attr_accessor :path
    attr_accessor :content
  end
end
