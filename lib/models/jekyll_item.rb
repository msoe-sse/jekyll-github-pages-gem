# frozen_string_literal: true

##
# The base class for an item on a Jekyll website (e.g page, post)
class JekyllItem
  attr_accessor :title
  # The GitHub ref the page's markdown is at. This is used to indicate
  # whether a page is in PR or not
  attr_accessor :github_ref
  attr_accessor :pull_request_url
  attr_accessor :contents
end
