# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/services/github_service'
##
# This class shows the basic set up for a unit test in minitest
##
class TestExample < MiniTest::Unit::TestCase
  def setup
    puts 'WE SET THE TEST UP'
    puts system('pwd')
    @github_service = Services::GithubService.new('reponame', 'exampleuser', 'safepwd')
    @test_var = nil
  end

  def test_that_life_is_not_broken
    assert_equal(1, 1)
    assert_nil(@test_var)
  end
end
