# frozen_string_literal: true

##
# An object representing a post on the Jekyll website
class Post < JekyllItem
  attr_accessor :author
  attr_accessor :hero
  attr_accessor :overlay
  attr_accessor :contents
  attr_accessor :tags
  # Path to the markdown post starting at the root of the repository
  attr_accessor :file_path
end
