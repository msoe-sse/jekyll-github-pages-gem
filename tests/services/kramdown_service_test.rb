# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../test_helper'

class KramdownServiceTest < BaseGemTest
  LEAD_BREAK_SECTION = "{: .lead}\r\n<!–-break-–>"
  def setup
    @KramdownService = Services::KramdownService.new
  end
  def test_get_preview_should_convert_markdown_to_html
    # Arrange
    markdown = %(#Andy is cool Andy is nice)

    # Act
    result = @KramdownService.get_preview(markdown)

    # Assert
    assert result != nil 
  end
  
  def test_get_preview_get_preview_should_not_update_the_src_atribute_of_image_tags_if_no_uploader_or_PostImage_exists_in_PostImageManager    # Arrange
    mock_uploader = create_mock_uploader('preview_no image.png', 'my cache', nil)
    preview_uploader = create_preview_uploader('no image.png', mock_uploader)
    post_image = create_post_image('no image2.png', 'contents')

    PostImageManager.instance.expects(:uploaders).returns([ preview_uploader ])
    PostImageManager.instance.expects(:downloaded_images).returns([ post_image ])

    markdown = '![20170610130401_1.jpg](/assets/img/20170610130401_1.jpg)'

    # Act
    result = @KramdownService.get_preview(markdown)

    # Assert
    assert_equal "<p><img src=\"/assets/img/20170610130401_1.jpg\" alt=\"20170610130401_1.jpg\" /></p>\n", result
  end

  def test_get_preview_get_preview_should_update_the_src_attribute_of_image_tags_if_an_uploader_exists_in_PostImageManager    # Arrange
    mock_uploader = create_mock_uploader('preview_20170610130401_1.jpg', 'my cache/preview_20170610130401_1.jpg', nil)
    preview_uploader = create_preview_uploader('20170610130401_1.jpg', mock_uploader)
    post_image = create_post_image('assets/img/20170610130401_1.jpg', 'contents')

    PostImageManager.instance.expects(:uploaders).returns([ preview_uploader ])
    PostImageManager.instance.expects(:downloaded_images).returns([ post_image ]).never

    markdown = '![My Alt Text](/assets/img/20170610130401_1.jpg)'
    expected_html = "<p><img src=\"/uploads/tmp/my cache/preview_20170610130401_1.jpg\" alt=\"My Alt Text\" /></p>\n"

    # Act
    result = @KramdownService.get_preview(markdown)

    # Assert
    assert_equal expected_html, result
  end

  def test_get_preview_get_preview_should_update_the_src_attribute_of_image_tags_if_a_PostImage_exists_in_PostImageManager    # Arrange
    post_image = create_post_image('assets/img/20170610130401_1.jpg', 'contents')
    markdown = '![My Alt Text](/assets/img/20170610130401_1.jpg)'
    expected_html = "<p><img src=\"data:image/jpg;base64,contents\" alt=\"My Alt Text\" /></p>\n"

    PostImageManager.instance.expects(:uploaders).returns([])
    PostImageManager.instance.expects(:downloaded_images).returns([ post_image ])

    # Act
    result = @KramdownService.get_preview(markdown)

    # Assert
    assert_equal expected_html, result
  end

  # Test Case for Issue 22 on GitHub
  def test_get_preview_get_preview_should_update_the_src_attribute_of_images_tags_if_an_uploader_with_a_formatted_filename_exists_in_PostImageManager    # Arrange
    mock_uploader = create_mock_uploader('preview_My_File.jpg', 'my cache/preview_My_File.jpg', nil)
    preview_uploader = create_preview_uploader('My_File.jpg', mock_uploader)

    PostImageManager.instance.expects(:uploaders).returns([ preview_uploader ])

    markdown = '![My Alt Text](/assets/img/My File.jpg)'
    expected_html = "<p><img src=\"/uploads/tmp/my cache/preview_My_File.jpg\" alt=\"My Alt Text\" /></p>\n"

    # Act
    result = @KramdownService.get_preview(markdown)

    # Assert
    assert_equal expected_html, result
  end

  def test_get_image_filename_from_markdown_get_image_filename_from_markdown_should_return_nil_if_the_markdown_doesnt_include_an_image_with_a_given_filename    # Arrange
    markdown = '![My Alt Text](/assets/img/20170610130401_1.jpg)'

    # Act
    result = @KramdownService.get_image_filename_from_markdown('my file.jpg', markdown)

    # Assert
    assert_nil result
  end

  def test_get_image_filename_from_markdown_get_image_filename_from_markdown_should_return_a_filename_if_the_markdown_does_include_an_image_with_a_given_filename    # Arrange
    markdown = '![My Alt Text](/assets/img/20170610130401_1.jpg)'

    # Act
    result = @KramdownService.get_image_filename_from_markdown('20170610130401_1.jpg', markdown)

    # Assert
    assert_equal '20170610130401_1.jpg', result
  end

  # Test Case for Issue 22 on GitHub
  def test_get_image_filename_from_markdown_get_image_filename_from_markdown_should_return_true_if_the_markdown_does_include_an_image_with_a_given_filename_and_the_filename_has_been_formatted_by_CarrierWave    # Arrange
    markdown = '![My Alt Text](/assets/img/My File.jpg)'

    # Act
    result = @KramdownService.get_image_filename_from_markdown('My_File.jpg', markdown)

    # Assert
    assert_equal 'My File.jpg', result
  end

  def test_get_all_image_paths_get_all_image_paths_should_return_all_image_paths_given_some_markdown    # Arrange
    markdown = "![My Alt Text](/assets/img/My File.jpg)\r\n![My Alt Text](/assets/img/My File2.jpg)"

    # Act
    result = @KramdownService.get_all_image_paths(markdown)

    # Assert
    assert_equal 2, result.length
    assert_equal 'assets/img/My File.jpg', result[0]
    assert_equal 'assets/img/My File2.jpg', result[1]
  end

  def test_get_all_images_paths_get_all_images_paths_should_not_return_image_paths_from_URIs    # Arrange
    markdown = '![My Alt Text](https://google.com/blah.jpg)'

    # Act
    result = @KramdownService.get_all_image_paths(markdown)

    # Assert
    assert_equal 0, result.length
  end

  def test_create_jekyll_post_text_create_jekyll_post_text_should_return_text_for_a_formatted_post    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
hero: https://source.unsplash.com/collection/145103/
overlay: green
published: true
---
#{LEAD_BREAK_SECTION}
# An H1 tag\r
##An H2 tag)

    # Act
    result = @KramdownService.create_jekyll_post_text("#An H1 tag\r\n##An H2 tag", 'Andy Wojciechowski', 
                                                     'Some Post', '', 'green', '')


    # Assert
    assert_equal expected_post, result
  end

  def test_create_jekyll_post_text_create_jekyll_post_text_should_return_a_formatted_post_given_valid_post_tags    # Arrange
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
#{LEAD_BREAK_SECTION}
# An H1 tag\r
##An H2 tag)
    # Act
    result = @KramdownService.create_jekyll_post_text("#An H1 tag\r\n##An H2 tag",
                                                     'Andy Wojciechowski', 
                                                     'Some Post', 
                                                     'announcement, info,    hack n tell     ', 
                                                     'green', '')
    # Assert
    assert_equal expected_post, result
  end

  def test_create_jekyll_post_text_create_jekyll_post_text_should_add_a_space_after_the_#_symbols_indicating_a_header_tag    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
hero: https://source.unsplash.com/collection/145103/
overlay: green
published: true
---
#{LEAD_BREAK_SECTION}
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
    result = @KramdownService.create_jekyll_post_text(markdown_text, 'Andy Wojciechowski', 'Some Post', '', 'green', '')

    # Assert
    assert_equal expected_post, result
  end

  def test_create_jekyll_post_text_create_jekyll_post_text_should_only_add_one_space_after_a_header    # Arrange
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
#{LEAD_BREAK_SECTION}
# An H1 tag\r
##An H2 tag)
    # Act
        result = @KramdownService.create_jekyll_post_text("# An H1 tag\r\n##An H2 tag",
                                                         'Andy Wojciechowski', 'Some Post',
                                                          'announcement, info', 'green', '')
        # Assert
        assert_equal expected_post, result
  end

  def test_create_jekyll_post_text_create_jekyll_post_text_should_substitute_the_given_hero_if_its_not_empty    # Arrange
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
#{LEAD_BREAK_SECTION}
# An H1 tag\r
##An H2 tag)
        # Act
        result = @KramdownService.create_jekyll_post_text("# An H1 tag\r\n##An H2 tag",
                                                         'Andy Wojciechowski', 'Some Post',
                                                          'announcement, info', 'green', 'bonk')
        # Assert
        assert_equal expected_post, result
  end

  def test_create_jekyll_post_text_create_jekyll_post_text_should_add_a_line_break_before_a_reference_style_image_if_the_markdown_starts_with_a_reference_style_image
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
#{LEAD_BREAK_SECTION}
\r
#{markdown})

    # Act
    result = @KramdownService.create_jekyll_post_text(markdown, 'Andy Wojciechowski', 'Some Post', 
                                                    'announcement, info', 'green', 'bonk')
    # Assert
    assert_equal expected_post, result
  end
end
