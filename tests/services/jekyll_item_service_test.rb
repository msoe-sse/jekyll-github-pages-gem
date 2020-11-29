# frozen_string_literal: true

require_relative '../test_helper'

class JekyllItemServiceTest < BaseGemTest
  def setup
    @repo_name = 'msoe-sg/test-jekyll-site'
    @access_token = 'auth_token'
  end
  
  def test_initialize_should_raise_argument_error_when_factory_does_not_inherit_from_base_factory
    # Act / Assert
    -> { Services::JekyllItemService.new(@repo_name, @access_token, 1) }.must_raise ArgumentError
  end

  def test_get_all_jekyll_items_in_collection_from_default_branch_should_return_all_jekyll_items_from_the_default_branch
    # Arrange
    post1 = create_dummy_api_resource(path: '_posts/post1.md')
    post2 = create_dummy_api_resource(path: '_posts/post2.md')
    post3 = create_dummy_api_resource(path: '_posts/post3.md')

    post1_model = create_post_model(title: 'post 1', author: 'Andy Wojciechowski', hero: 'hero 1',
                                    overlay: 'overlay 1', contents: '##post1', tags: %w[announcement info])
    post2_model = create_post_model(title: 'post 2', author: 'Grace Fleming', hero: 'hero 2',
                                    overlay: 'overlay 2', contents: '##post2', tags: ['announcement'])
    post3_model = create_post_model(title: 'post 3', author: 'Sabrina Stangler', hero: 'hero 3',
                                    overlay: 'overlay 3', contents: '###post3', tags: ['info'])

    Services::GithubService.any_instance.expects(:get_contents_from_path)
                           .with('_posts')
                           .returns([post1, post2, post3])

    Services::GithubService.any_instance.expects(:get_text_contents_from_file)
                           .with('_posts/post1.md')
                           .returns('post 1 text content')
    Services::GithubService.any_instance.expects(:get_text_contents_from_file)
                           .with('_posts/post2.md')
                           .returns('post 2 text content')
    Services::GithubService.any_instance.expects(:get_text_contents_from_file)
                           .with('_posts/post3.md')
                           .returns('post 3 text content')

    Factories::PostFactory.any_instance.expects(:create_jekyll_item)
                          .with('post 1 text content', '_posts/post1.md', nil).returns(post1_model)
    Factories::PostFactory.any_instance.expects(:create_jekyll_item)
                          .with('post 2 text content', '_posts/post2.md', nil).returns(post2_model)
    Factories::PostFactory.any_instance.expects(:create_jekyll_item)
                          .with('post 3 text content', '_posts/post3.md', nil).returns(post3_model)
    
    item_service = create_jekyll_item_service(Factories::PostFactory.new)

    # Act
    result = item_service.get_all_jekyll_items_in_collection_from_default_branch('_posts')

    # Assert
    assert_equal [post1_model, post2_model, post3_model], result
  end
  
  def test_get_all_jekyll_items_in_collection_from_default_branch_should_not_return_items_in_pr_when_specified
    # Arrange
    post = create_dummy_api_resource(path: '_posts/post1.md')

    post_model = create_post_model(title: 'post 1', author: 'Andy Wojciechowski', hero: 'hero 1',
                                    overlay: 'overlay 1', contents: '##post1', tags: %w[announcement info])

    Services::GithubService.any_instance.expects(:get_contents_from_path)
                           .with('_posts')
                           .returns([post_model)
    Services::GithubService.any_instance.expects(:get_text_contents_from_file)
                           .with('_posts/post1.md')
                           .returns('post 1 text content')
    Factories::PostFactory.any_instance.expects(:create_jekyll_item)
                          .with('post 1 text content', '_posts/post1.md', nil).returns(post_model)
    
    item_service = create_jekyll_item_service(Factories::PostFactory.new)

    # Act
    result = item_service.get_all_jekyll_items_in_collection_from_default_branch('_posts', [post_model])
    
    # Assert
    assert result.empty?
  end

  def test_get_all_jekyll_items_in_collection_and_in_pr_should_return_all_added_or_modified_items_in_collection_that_are_in_pr
    # Arrange
    pr_body = 'This pull request was opened automatically by the SG website editor.'
    post_content = create_dummy_api_resource(content: 'PR base 64 content', path: '_posts/sample.md')
    post_model = create_post_model(title: 'post', author: 'Andy Wojciechowski', hero: 'hero',
                                   overlay: 'overlay', contents: '#post', tags: %w[announcement info])
    pr_files = [
      create_pull_request_file_hash('myref', '_posts/sample.md')
    ]

    Services::GithubService.any_instance.expects(:get_open_pull_requests_with_body).with(pr_body)
                           .returns([create_pull_request_hash('andy-wojciechowski', pr_body, 3, 'https://example.com/pull/1')])

    Services::GithubService.any_instance.expects(:get_pr_files).with(3).returns(pr_files)

    Services::GithubService.any_instance.expects(:get_ref_from_contents_url).with(pr_files[0][:contents_url]).returns('myref')
    Services::GithubService.any_instance.expects(:get_contents_from_path).with('_posts/sample.md', 'myref').returns(post_content)

    Services::GithubService.any_instance.expects(:get_text_content_from_file).with('_posts/sample.md', 'myref').returns('PR content')
    Factories::PostFactory.any_instance.expects(:create_jekyll_item)
                          .with('PR content', 'sample.md', 'https://example.com/pull/1').returns(post_model)
    
    item_service = create_jekyll_item_service(Factories::PostFactory.new)

    # Act
    result = item_service.get_all_jekyll_items_in_collection_and_in_pr('_posts', pr_body)

    # Assert
    assert_equal [post_model], result[:added_or_modified_items_in_pr]
    assert result[:deleted_items_in_pr].empty?
  end

  def test_get_all_jekyll_items_in_collection_and_in_pr_should_return_all_deleted_items_in_collection_that_are_in_pr
    # Arrange
    pr_body = 'This pull request was opened automatically by the SG website editor.'
    post_content = create_dummy_api_resource(content: 'PR base 64 content', path: '_posts/sample.md')
    post_model = create_post_model(title: 'post', author: 'Andy Wojciechowski', hero: 'hero',
                                   overlay: 'overlay', contents: '#post', tags: %w[announcement info])
    pr_files = [
      create_pull_request_file_hash('myref', '_posts/sample.md', true)
    ]

    Services::GithubService.any_instance.expects(:get_open_pull_requests_with_body).with(pr_body)
                           .returns([create_pull_request_hash('andy-wojciechowski', pr_body, 3, 'https://example.com/pull/1')])

    Services::GithubService.any_instance.expects(:get_pr_files).with(3).returns(pr_files)

    Services::GithubService.any_instance.expects(:get_ref_from_contents_url).with(pr_files[0][:contents_url]).returns('myref')
    Services::GithubService.any_instance.expects(:get_contents_from_path).with('_posts/sample.md', 'myref').returns(post_content)

    Services::GithubService.any_instance.expects(:get_text_content_from_file).with('_posts/sample.md', 'myref').returns('PR content')
    Factories::PostFactory.any_instance.expects(:create_jekyll_item)
                          .with('PR content', 'sample.md', 'https://example.com/pull/1').returns(post_model)
    
    item_service = create_jekyll_item_service(Factories::PostFactory.new)

    # Act
    result = item_service.get_all_jekyll_items_in_collection_and_in_pr('_posts', pr_body)

    # Assert
    assert result[:added_or_modified_items_in_pr].empty?
    assert_equal [post_model], result[:deleted_items_in_pr]
  end

  def test_get_all_jekyll_items_in_collection_and_in_pr_should_not_return_items_that_are_not_in_given_collection
    # Arrange
    pr_body = 'This pull request was opened automatically by the SG website editor.'
    resource_content = create_dummy_api_resource(content: 'PR base 64 content', path: '_resources/sample.md')
    pr_files = [
      create_pull_request_file_hash('myref', '_resources/sample.md', true)
    ]

    Services::GithubService.any_instance.expects(:get_open_pull_requests_with_body).with(pr_body)
                           .returns([create_pull_request_hash('andy-wojciechowski', pr_body, 3, 'https://example.com/pull/1')])

    Services::GithubService.any_instance.expects(:get_pr_files).with(3).returns(pr_files)

    Services::GithubService.any_instance.expects(:get_ref_from_contents_url).with(pr_files[0][:contents_url]).returns('myref')
    Services::GithubService.any_instance.expects(:get_contents_from_path).with('_resources/sample.md', 'myref').returns(post_content)
    
    item_service = create_jekyll_item_service(Factories::PostFactory.new)

    # Act
    result = item_service.get_all_jekyll_items_in_collection_and_in_pr('_posts', pr_body)

    # Assert
    assert result[:added_or_modified_items_in_pr].empty?
    assert result[:deleted_items_in_pr].empty?
  end
  
  def test_get_jekyll_item_should_return_item_model_from_default_branch_when_not_given_pr_body
    # Arrange
    page_model = create_page_model(title: 'About', permalink: '/about/', contents: 'text contents')

    Services::GithubService.any_instance.expects(:get_text_contents_from_file).with('about.md').returns('text contents')
    Factories::PageFactory.any_instance.expects(:create_jekyll_item).with('text contents', nil, nil).returns(page_model)
    
    jekyll_item_service = create_jekyll_item_service(Factories::PageFactory.new)

    # Act
    result = jekyll_item_service.get_jekyll_item('about.md')

    # Assert
    assert_equal page_model, result
  end

  def test_get_jekyll_item_should_return_item_model_from_default_branch_when_there_are_no_open_prs_with_given_body
    # Arrange
    pr_body = 'my body'
    page_model = create_page_model(title: 'About', permalink: '/about/', contents: 'text contents')

    Services::GithubService.any_instance.expects(:get_open_pull_requests_with_body).with(pr_body).returns([])
    Services::GithubService.any_instance.expects(:get_text_contents_from_file).with('about.md').returns('text contents')
    Factories::PageFactory.any_instance.expects(:create_jekyll_item).with('text contents', nil, nil).returns(page_model)
    
    jekyll_item_service = create_jekyll_item_service(Factories::PageFactory.new)

    # Act
    result = jekyll_item_service.get_jekyll_item('about.md', pr_body)

    # Assert
    assert_equal page_model, result
  end

  def test_get_jekyll_item_should_return_item_model_from_default_branch_when_first_open_pr_has_no_markdown_files
    # Arrange
    pr_body = 'my body'
    page_model = create_page_model(title: 'About', permalink: '/about/', contents: 'text contents')

    Services::GithubService.any_instance.expects(:get_open_pull_requests_with_body)
                           .with(pr_body).returns([
                                                    create_pull_request_hash('andy-wojciechowski', pr_body, 1),
                                                    create_pull_request_hash('andy-wojciechowski', pr_body, 2)
                                                  ])
    Services::GithubService.any_instance.expects(:get_pr_files).with(1).returns([
                                                                                  create_pull_request_file_hash('ref', 'myfile.jpg'),
                                                                                  create_pull_request_file_hash('ref', 'myfile.csv')
                                                                                ])
    Services::GithubService.any_instance.expects(:get_text_contents_from_file).with('about.md').returns('text contents')
    Factories::PageFactory.any_instance.expects(:create_jekyll_item).with('text contents', nil, nil).returns(page_model)
    
    jekyll_item_service = create_jekyll_item_service(Factories::PageFactory.new)

    # Act
    result = jekyll_item_service.get_jekyll_item('about.md', pr_body)

    # Assert
    assert_equal page_model, result
  end

  def test_get_jekyll_item_should_return_item_model_from_other_branch_when_first_open_pr_has_markdown_files
    # Arrange
    pr_body = 'my body'
    page_model = create_page_model(title: 'About', permalink: '/about/', contents: 'text contents', github_ref: 'ref')

    Services::GithubService.any_instance.expects(:get_open_pull_requests_with_body)
                           .with(pr_body).returns([
                                                    create_pull_request_hash('andy-wojciechowski', pr_body, 1, 'http://example.com/pulls/1'),
                                                    create_pull_request_hash('andy-wojciechowski', pr_body, 2)
                                                  ])
    Services::GithubService.any_instance.expects(:get_pr_files).with(1).returns([
                                                                                  create_pull_request_file_hash('ref', 'myfile.jpg'),
                                                                                  create_pull_request_file_hash('ref', 'page.md'),
                                                                                  create_pull_request_file_hash('ref', 'otherfile.md')
                                                                                ])
    Services::GithubService.any_instance.expects(:get_ref_from_contents_url).with('http://example.com?ref=ref').returns('ref')
    Services::GithubService.any_instance.expects(:get_text_contents_from_file).with('about.md', 'ref').returns('text contents')
    Factories::PageFactory.any_instance.expects(:create_jekyll_item).with('text contents', 'ref', 'http://example.com/pulls/1').returns(page_model)
    
    jekyll_item_service = create_jekyll_item_service(Factories::PageFactory.new)

    # Act
    result = jekyll_item_service.get_markdown_page('about.md', pr_body)

    # Assert
    assert_equal page_model, result
  end

  def test_save_jekyll_item_update_should_update_branch_when_given_a_ref
    # Arrange
    Services::GithubService.any_instance.expects(:get_ref_name_by_sha).with('my ref').returns('heads/editPageAbout')
    Services::GithubService.any_instance.expects(:get_base_tree_for_branch).with('my ref').returns('master tree sha')
    Services::GithubService.any_instance.expects(:create_text_blob).with('# hello').returns('page blob sha')
    Services::GithubService.any_instance.expects(:create_new_tree_with_blobs)
                           .with([create_file_info_hash('about.md', 'page blob sha')], 'master tree sha')
                           .returns('new tree sha')
    Services::GithubService.any_instance.expects(:commit_and_push_to_repo)
                           .with('Edited page about', 'new tree sha',
                                 'my ref', 'heads/editPageAbout').once
    
    jekyll_item_service = create_jekyll_item_service(Factories::PageFactory.new)

    # Act
    jekyll_item_service.save_page_update('about.md', 'about', '# hello', 'my ref')

    # No Assert - taken care of with mocha mock setups
  end

  def test_save_jekyll_item_update_should_edit_item_and_create_a_pull_request_when_not_given_a_ref
    # Arrange
    Utilities.expects(:generate_random_string).with(10).returns('Identifer')
    Services::GithubService.any_instance.expects(:get_master_head_sha).returns('master head sha')
    Services::GithubService.any_instance.expects(:get_base_tree_for_branch)
                           .with('master head sha').returns('master tree sha')
    Services::GithubService.any_instance.expects(:create_ref_if_necessary)
                           .with('heads/editPageAboutIdentifer', 'master head sha').once
    Services::GithubService.any_instance.expects(:create_text_blob).with('# hello').returns('page blob sha')
    Services::GithubService.any_instance.expects(:create_new_tree_with_blobs)
                           .with([create_file_info_hash('about.md', 'page blob sha')], 'master tree sha')
                           .returns('new tree sha')
    Services::GithubService.any_instance.expects(:commit_and_push_to_repo)
                           .with('Edited page About', 'new tree sha',
                                 'master head sha', 'heads/editPageAboutIdentifer').returns('sha')
    Services::GithubService.any_instance.expects(:create_pull_request)
                           .with('editPageAboutIdentifer',
                                 'master',
                                 'Edited page About',
                                 @pr_body,
                                 @reviewers).returns('http://example.com')
    
    jekyll_item_service = create_jekyll_item_service(Factories::PageFactory.new)

    # Act
    result = jekyll_item_service.save_page_update('about.md', 'About', '# hello', nil, @pr_body, @reviewers)

    assert_equal 'http://example.com', result.pull_request_url
    assert_equal 'sha', result.github_ref
  end

  private

  def create_jekyll_item_service(factory)
    Services::JekyllItemService.new(@repo_name, @access_token, factory)
  end
  
  def create_post_model(parameters)
    post_model = Post.new
    post_model.title = parameters[:title]
    post_model.author = parameters[:author]
    post_model.hero = parameters[:hero]
    post_model.overlay = parameters[:overlay]
    post_model.contents = parameters[:contents]
    post_model.tags = parameters[:tags]
    post_model
  end

  def create_page_model(parameters)
    page_model = Page.new
    page_model.title = parameters[:title]
    page_model.permalink = parameters[:permalink]
    page_model.contents = parameters[:contents]
    page_model.github_ref = parameters[:github_ref]
    page_model
  end
end
