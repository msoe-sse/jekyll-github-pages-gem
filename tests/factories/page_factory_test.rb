# frozen_string_literal: true

require_relative '../test_helper'

class PageFactoryTest < BaseGemTest
  def setup
    @page_factory = Factories::PageFactory.new
  end

  def test_create_page_should_return_nil_if_given_a_nil_value_for_page_contents
    # Act
    result = @page_factory.create_page(nil, nil)

    # Assert
    assert_nil result
  end

  def test_create_page_should_return_nil_if_given_a_nonstring_type_for_page_contents
    # Act
    result = @page_factory.create_page(1, 'myref')

    # Assert
    assert_nil result
  end

  def test_create_page_should_return_a_page_model_with_correct_values
    # Arrange
    page_contents = %(---
layout: page
title: About
permalink: /about/
---
#An H1 tag
##An H2 tag)

    # Act
    result = @page_factory.create_page(page_contents, 'myref')

    # Assert
    assert_equal 'myref', result.github_ref
    assert_equal 'About', result.title
    assert_equal '/about/', result.permalink
    assert_equal "#An H1 tag\n##An H2 tag", result.contents
  end

  def test_create_page_should_return_a_page_model_with_correct_values_given_a_page_with_slash_r_slash_n_line_breaks
    # Arrange
    page_contents = %(---
layout: page\r
title: About\r
permalink: /about/\r
---\r
#An H1 tag\r
##An H2 tag)

    # Act
    result = @page_factory.create_page(page_contents, 'myref')

    # Assert
    assert_equal 'myref', result.github_ref
    assert_equal "About\r", result.title
    assert_equal "/about/\r", result.permalink
    assert_equal "#An H1 tag\r\n##An H2 tag", result.contents
  end
end
