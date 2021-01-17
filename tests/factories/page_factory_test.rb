# frozen_string_literal: true

require_relative '../test_helper'

##
# Test Class containing unit tests for the PageFactory class
class PageFactoryTest < BaseGemTest
  def setup
    @page_factory = Factories::PageFactory.new
  end

  def test_create_jekyll_item_should_return_nil_if_given_a_nil_value_for_page_contents
    # Act
    result = @page_factory.create_jekyll_item(nil, nil, nil)

    # Assert
    assert_nil result
  end

  def test_create_jekyll_item_should_return_nil_if_given_a_nonstring_type_for_page_contents
    # Act
    result = @page_factory.create_jekyll_item(1, 'myref', 'http://github.com/pulls/1')

    # Assert
    assert_nil result
  end

  def test_create_jekyll_item_should_return_a_page_model_with_correct_values
    # Arrange
    page_contents = %(---
layout: page
title: About
permalink: /about/
---
#An H1 tag
##An H2 tag)

    # Act
    result = @page_factory.create_jekyll_item(page_contents, 'myref', 'http://github.com/pulls/1')

    # Assert
    assert_equal 'http://github.com/pulls/1', result.pull_request_url
    assert_equal 'myref', result.github_ref
    assert_equal 'About', result.title
    assert_equal '/about/', result.permalink
    assert_equal "#An H1 tag\n##An H2 tag", result.contents
  end

  def test_create_jekyll_item_should_return_a_page_model_with_correct_values_given_a_page_with_slash_r_slash_n_line_breaks
    # Arrange
    page_contents = %(---
layout: page\r
title: About\r
permalink: /about/\r
---\r
#An H1 tag\r
##An H2 tag)

    # Act
    result = @page_factory.create_jekyll_item(page_contents, 'myref', 'http://github.com/pulls/1')

    # Assert
    assert_equal 'http://github.com/pulls/1', result.pull_request_url
    assert_equal 'myref', result.github_ref
    assert_equal "About\r", result.title
    assert_equal "/about/\r", result.permalink
    assert_equal "#An H1 tag\r\n##An H2 tag", result.contents
  end

  def test_create_jekyll_item_text_should_raise_argument_error_when_not_given_text
    # Act / Assert
    assert_raises ArgumentError do
      @page_factory.create_jekyll_item_text({
                                              title: 'About',
                                              permalink: '/about//'
                                            })
    end
  end

  def test_create_jekyll_item_text_should_raise_argument_error_when_not_given_a_title
    # Act / Assert
    assert_raises ArgumentError do
      @page_factory.create_jekyll_item_text({
                                              text: "#An H1 tag\r\n##An H2 tag",
                                              permalink: '/about//'
                                            })
    end
  end

  def test_create_jekyll_item_text_should_raise_argument_error_when_not_given_a_permalink
    # Act / Assert
    assert_raises ArgumentError do
      @page_factory.create_jekyll_item_text({
                                              text: "#An H1 tag\r\n##An H2 tag",
                                              title: 'About'
                                            })
    end
  end

  def test_create_jekyll_item_text_should_return_text_for_a_formatted_page
    # Arrange
    expected_page = %(---
layout: page
title: About
permalink: /about/
---
# An H1 tag\r
##An H2 tag)

    # Act
    result = @page_factory.create_jekyll_item_text({
                                                     text: "#An H1 tag\r\n##An H2 tag",
                                                     title: 'About',
                                                     permalink: '/about/'
                                                   })

    # Assert
    assert_equal expected_page, result
  end

  def test_create_jekyll_item_text_should_add_a_space_after_the_hash_symbol_indicating_header_tag
    # Arrange
    expected_page = %(---
layout: page
title: About
permalink: /about/
---
# H1 header\r
\r
## H2 header\r
\r
### H3 header\r
\r
#### H4 header\r
\r
##### H5 header\r
\r
###### H6 header)

    markdown_text = %(#H1 header\r
\r
##H2 header\r
\r
###H3 header\r
\r
####H4 header\r
\r
#####H5 header\r
\r
######H6 header)

    # Act
    result = @page_factory.create_jekyll_item_text({
                                                     text: markdown_text,
                                                     title: 'About',
                                                     permalink: '/about/'
                                                   })

    # Assert
    assert_equal expected_page, result
  end

  def test_create_jekyll_item_text_should_add_a_line_break_before_a_reference_style_img_if_markdown_starts_with_a_reference_style_img
    # Arrange
    image_tag = "\r\n![alt text][logo]"
    markdown = "[logo]: https://ieeextreme.org/wp-content/uploads/2019/05/Xtreme_colour-e1557478323964.png#{image_tag}"

    expected_page = %(---
layout: page
title: About
permalink: /about/
---
\r
#{markdown})

    # Act
    result = @page_factory.create_jekyll_item_text({
                                                     text: markdown,
                                                     title: 'About',
                                                     permalink: '/about/'
                                                   })

    # Assert
    assert_equal expected_page, result
  end
end
