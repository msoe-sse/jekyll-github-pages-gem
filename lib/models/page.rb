# frozen_string_literal: true

class Page
  attr_accessor :title
  attr_accessor :permalink
  attr_accessor :contents
  # The GitHub ref the page's markdown is at. This is used to indicate
  # whether a page is in PR or not
  attr_accessor :github_ref
end
