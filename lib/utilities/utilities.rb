# frozen_string_literal: true

##
# An internal module containing different utility methods used in the gem
module Utilities
  ##
  # Taken from: https://www.rubyguides.com/2015/03/ruby-random/
  def generate_random_string(length)
    charset = Array('A'..'Z') + Array('a'..'z')
    Array.new(length) { charset.sample }.join
  end
end
