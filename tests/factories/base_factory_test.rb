# frozen_string_literal: true

require_relative '../test_helper'

##
# Test class for the BaseFactory class
class BaseFactoryTest < BaseGemTest
  def setup
    @base_factory = Factories::BaseFactory.new
  end

  def test_create_file_path_for_item_should_return_file_path_in_root_directory_when_not_given_collection_name
    # Act
    result = @base_factory.create_file_path_for_item('My Item')

    # Assert
    assert_equal 'MyItem.md', result
  end

  def test_create_file_path_for_item_should_return_file_path_in_collection_directory_when_given_collection_name
    # Act
    result = @base_factory.create_file_path_for_item('My Item', '_ITEms')

    # Assert
    assert_equal '_items/MyItem.md', result
  end

  def test_create_jekyll_item_should_raise_not_implemented_error_when_not_implemented_in_subclasses
    # Act / Assert
    assert_raises NotImplementedError do
      @base_factory.create_jekyll_item('contents', 'path.md', 'ref', 'url')
    end
  end

  def test_create_jekyll_item_text_should_raise_not_implemented_error_when_not_implemented_in_subclasses
    # Act / Assert
    assert_raises NotImplementedError do
      @base_factory.create_jekyll_item_text({ title: 'My Title' })
    end
  end
end
