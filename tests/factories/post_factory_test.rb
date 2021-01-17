# frozen_string_literal: true

require_relative '../test_helper'

# tests the post factory class
class PostFactoryTest < BaseGemTest
  LEAD_BREAK_SECTION1 = "{: .lead}\r\n<!–-break-–>"
  LEAD_BREAK_SECTION2 = "{: .lead}\n<!–-break-–>"

  def setup
    @post_factory = Factories::PostFactory.new
  end

  def test_create_file_path_for_item_should_return_file_path_in_root_directory_when_not_given_collection_name
    # Act
    result = @post_factory.create_file_path_for_item('My Post')

    # Assert
    assert_equal "#{DateTime.now.strftime('%Y-%m-%d')}-MyPost.md", result
  end

  def test_create_file_path_for_item_should_return_file_path_in_collection_directory_when_given_collection_name
    # Act
    result = @post_factory.create_file_path_for_item('My Post', '_POSts')

    # Assert
    assert_equal "_posts/#{DateTime.now.strftime('%Y-%m-%d')}-MyPost.md", result
  end

  def test_create_jekyll_item_should_return_nil_if_given_a_nil_value_for_post_contents
    # Act
    result = @post_factory.create_jekyll_item(nil, nil, nil)

    # Assert
    assert_nil result
  end

  def test_create_jekyll_item_should_return_nil_if_given_a_nonstring_type_for_post_contents
    # Act
    result = @post_factory.create_jekyll_item(1, 'my post.md', 'https://example.com/pull/1')

    # Assert
    assert_nil result
  end

  def test_create_jekyll_item_should_return_a_post_model_with_correct_values
    # Arrange
    post_contents = %(---
layout: post
title: Some Post
author: Andrew Wojciechowski
tags:
  - announcement
  - info
hero: https://source.unsplash.com/collection/145103/
overlay: green
---
#{LEAD_BREAK_SECTION1}
#An H1 tag
##An H2 tag)

    # Act
    result = @post_factory.create_jekyll_item(post_contents, 'my post.md', 'https://example.com/pull/1')

    # Assert
    assert_equal 'my post.md', result.file_path
    assert_equal 'https://example.com/pull/1', result.pull_request_url
    assert_equal 'Some Post', result.title
    assert_equal 'Andrew Wojciechowski', result.author
    assert_equal 'announcement, info', result.tags
    assert_equal '', result.hero
    assert_equal 'green', result.overlay
    assert_equal "#An H1 tag\n##An H2 tag", result.contents
  end

  def test_create_jekyll_item_should_return_a_post_model_with_correct_values_given_a_post_with_slash_r_slash_n_line_breaks
    # Arrange
    post_contents = %(---
layout: post\r
title: Some Post\r
author: Andrew Wojciechowski\r
tags:\r
  - announcement\r
  - info\r
hero: https://source.unsplash.com/collection/145103/blah.com\r
overlay: green\r
---\r
#{LEAD_BREAK_SECTION2}
#An H1 tag\r
##An H2 tag)

    # Act
    result = @post_factory.create_jekyll_item(post_contents, 'my post.md', 'https://example.com/pull/1')

    # Assert
    assert_equal 'my post.md', result.file_path
    assert_equal 'https://example.com/pull/1', result.pull_request_url
    assert_equal "Some Post\r", result.title
    assert_equal "Andrew Wojciechowski\r", result.author
    assert_equal "announcement\r, info\r", result.tags
    assert_equal "https://source.unsplash.com/collection/145103/blah.com\r", result.hero
    assert_equal "green\r", result.overlay
    assert_equal "#An H1 tag\r\n##An H2 tag", result.contents
  end

  def test_create_jekyll_item_text_should_raise_argument_error_when_not_given_text
    # Act / Assert
    assert_raises ArgumentError do
      @post_factory.create_jekyll_item_text({
                                              title: 'About',
                                              author: 'Andy Wojciechowski'
                                            })
    end
  end

  def test_create_jekyll_item_text_should_raise_argument_error_when_not_given_a_title
    # Act / Assert
    assert_raises ArgumentError do
      @post_factory.create_jekyll_item_text({
                                              contents: "#An H1 tag\r\n##An H2 tag",
                                              author: 'Andy Wojciechowski'
                                            })
    end
  end

  def test_create_jekyll_item_text_should_raise_argument_error_when_not_given_a_author
    # Act / Assert
    assert_raises ArgumentError do
      @post_factory.create_jekyll_item_text({
                                              contents: "#An H1 tag\r\n##An H2 tag",
                                              title: 'About'
                                            })
    end
  end

  def test_create_jekyll_item_text_should_return_text_for_a_formatted_post
    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
hero: https://source.unsplash.com/collection/145103/
overlay: green
published: true
---
#{LEAD_BREAK_SECTION1}
# An H1 tag\r
##An H2 tag)

    # Act
    result = @post_factory.create_jekyll_item_text({
                                                     contents: "#An H1 tag\r\n##An H2 tag",
                                                     author: 'Andy Wojciechowski',
                                                     title: 'Some Post',
                                                     tags: '',
                                                     overlay: 'green',
                                                     hero: '',
                                                     set_published_property: true,
                                                     append_lead_break_section: true
                                                   })

    # Assert
    assert_equal expected_post, result
  end

  def test_create_jekyll_item_text_should_return_a_formatted_post_given_valid_post_tags
    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
tags:
  - announcement\r
  - info\r
  - hack n tell\r
hero: https://source.unsplash.com/collection/145103/
overlay: green
published: true
---
#{LEAD_BREAK_SECTION1}
# An H1 tag\r
##An H2 tag)

    # Act
    result = @post_factory.create_jekyll_item_text({
                                                     contents: "#An H1 tag\r\n##An H2 tag",
                                                     author: 'Andy Wojciechowski',
                                                     title: 'Some Post',
                                                     tags: 'announcement, info,    hack n tell     ',
                                                     overlay: 'green',
                                                     hero: '',
                                                     set_published_property: true,
                                                     append_lead_break_section: true
                                                   })
    # Assert
    assert_equal expected_post, result
  end

  def test_create_jekyll_item_text_should_add_a_space_after_the_hash_symbol_indicating_header_tag
    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
hero: https://source.unsplash.com/collection/145103/
overlay: green
published: true
---
#{LEAD_BREAK_SECTION1}
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
    result = @post_factory.create_jekyll_item_text({
                                                     contents: markdown_text,
                                                     author: 'Andy Wojciechowski',
                                                     title: 'Some Post',
                                                     tags: '',
                                                     overlay: 'green',
                                                     hero: '',
                                                     set_published_property: true,
                                                     append_lead_break_section: true
                                                   })

    # Assert
    assert_equal expected_post, result
  end

  def test_create_jekyll_item_text_should_only_add_one_space_after_a_header
    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
tags:
  - announcement\r
  - info\r
hero: https://source.unsplash.com/collection/145103/
overlay: green
published: true
---
#{LEAD_BREAK_SECTION1}
# An H1 tag\r
##An H2 tag)

    # Act
    result = @post_factory.create_jekyll_item_text({
                                                     contents: "#An H1 tag\r\n##An H2 tag",
                                                     author: 'Andy Wojciechowski',
                                                     title: 'Some Post',
                                                     tags: 'announcement, info',
                                                     overlay: 'green',
                                                     hero: '',
                                                     set_published_property: true,
                                                     append_lead_break_section: true
                                                   })

    # Assert
    assert_equal expected_post, result
  end

  def test_create_jekyll_item_text_should_substitute_the_given_hero_if_its_not_empty
    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
tags:
  - announcement\r
  - info\r
hero: bonk
overlay: green
published: true
---
#{LEAD_BREAK_SECTION1}
# An H1 tag\r
##An H2 tag)

    # Act
    result = @post_factory.create_jekyll_item_text({
                                                     contents: "#An H1 tag\r\n##An H2 tag",
                                                     author: 'Andy Wojciechowski',
                                                     title: 'Some Post',
                                                     tags: 'announcement, info',
                                                     overlay: 'green',
                                                     hero: 'bonk',
                                                     set_published_property: true,
                                                     append_lead_break_section: true
                                                   })

    # Assert
    assert_equal expected_post, result
  end

  def test_create_jekyll_item_text_should_add_a_line_break_before_a_reference_style_img_if_markdown_starts_with_a_reference_style_img
    image_tag = "\r\n![alt text][logo]"
    markdown = "[logo]: https://ieeextreme.org/wp-content/uploads/2019/05/Xtreme_colour-e1557478323964.png#{image_tag}"

    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
tags:
  - announcement\r
  - info\r
hero: bonk
overlay: green
published: true
---
#{LEAD_BREAK_SECTION1}
\r
#{markdown})

    # Act
    result = @post_factory.create_jekyll_item_text({
                                                     contents: markdown,
                                                     author: 'Andy Wojciechowski',
                                                     title: 'Some Post',
                                                     tags: 'announcement, info',
                                                     overlay: 'green',
                                                     hero: 'bonk',
                                                     set_published_property: true,
                                                     append_lead_break_section: true
                                                   })

    # Assert
    assert_equal expected_post, result
  end

  def test_create_jekyll_item_text_should_create_valid_post_when_all_optional_parameters_are_not_supplied
    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
---
# An H1 Tag)

    # Act
    result = @post_factory.create_jekyll_item_text({
                                                     title: 'Some Post',
                                                     author: 'Andy Wojciechowski',
                                                     contents: '# An H1 Tag'
                                                   })

    # Assert
    assert_equal expected_post, result
  end
end
