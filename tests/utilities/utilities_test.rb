# frozen_string_literal: true

require_relative '../test_helper'

class UtilitiesTest < BaseGemTest
  include Utilities

  def test_generate_random_string_should_generate_a_random_string_of_the_given_length
    # Act
    result = generate_random_string(10)

    # Assert
    assert_instance_of(String, result)
    assert_equal 10, result.length
  end
end
