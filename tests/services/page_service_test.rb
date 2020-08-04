# frozen_string_literal: true

require_relative '../test_helper'

##
# Test Class containing unit tests for the PageService class
class PageServiceTest < BaseGemTest
  def setup
    @page_service = Services::PageService.new('msoe-sg/test-jekyll-site', 'auth_token')
    @pr_body = 'This pull request was opened automatically by the jekyll website editor.'
    @reviewers = ['reviewer']
  end

  def test_get_markdown_page_should_return_page_model_from_default_branch_when_not_given_pr_body
    # Arrange
    page_model = create_page_model(title: 'About', permalink: '/about/', contents: 'text contents')

    Services::GithubService.any_instance.expects(:get_text_contents_from_file).with('about.md').returns('text contents')
    Factories::PageFactory.any_instance.expects(:create_page).with('text contents', nil, nil).returns(page_model)

    # Act
    result = @page_service.get_markdown_page('about.md')

    # Assert
    assert_equal page_model, result
  end

  def test_get_markdown_page_should_return_page_model_from_default_branch_when_there_are_no_open_prs_with_given_body
    # Arrange
    pr_body = 'my body'
    page_model = create_page_model(title: 'About', permalink: '/about/', contents: 'text contents')

    Services::GithubService.any_instance.expects(:get_open_pull_requests_with_body).with(pr_body).returns([])
    Services::GithubService.any_instance.expects(:get_text_contents_from_file).with('about.md').returns('text contents')
    Factories::PageFactory.any_instance.expects(:create_page).with('text contents', nil, nil).returns(page_model)

    # Act
    result = @page_service.get_markdown_page('about.md', pr_body)

    # Assert
    assert_equal page_model, result
  end

  def test_get_markdown_page_should_return_page_model_from_default_branch_when_first_open_pr_has_no_markdown_files
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
    Factories::PageFactory.any_instance.expects(:create_page).with('text contents', nil, nil).returns(page_model)

    # Act
    result = @page_service.get_markdown_page('about.md', pr_body)

    # Assert
    assert_equal page_model, result
  end

  def test_get_markdown_page_should_return_page_model_from_other_branch_when_first_open_pr_has_markdown_files
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
    Factories::PageFactory.any_instance.expects(:create_page).with('text contents', 'ref', 'http://example.com/pulls/1').returns(page_model)

    # Act
    result = @page_service.get_markdown_page('about.md', pr_body)

    # Assert
    assert_equal page_model, result
  end

  def test_save_page_update_should_update_branch_when_given_a_ref
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

    # Act
    @page_service.save_page_update('about.md', 'about', '# hello', 'my ref')

    # No Assert - taken care of with mocha mock setups
  end

  def test_save_page_update_should_edit_post_and_create_a_pull_request_when_not_given_a_ref
    # Arrange
    Services::GithubService.any_instance.expects(:get_master_head_sha).returns('master head sha')
    Services::GithubService.any_instance.expects(:get_base_tree_for_branch)
                           .with('master head sha').returns('master tree sha')
    Services::GithubService.any_instance.expects(:create_ref_if_necessary)
                           .with('heads/editPageAbout', 'master head sha').once
    Services::GithubService.any_instance.expects(:create_text_blob).with('# hello').returns('page blob sha')
    Services::GithubService.any_instance.expects(:create_new_tree_with_blobs)
                           .with([create_file_info_hash('about.md', 'page blob sha')], 'master tree sha')
                           .returns('new tree sha')
    Services::GithubService.any_instance.expects(:commit_and_push_to_repo)
                           .with('Edited page About', 'new tree sha',
                                 'master head sha', 'heads/editPageAbout').returns('sha')
    Services::GithubService.any_instance.expects(:create_pull_request)
                           .with('editPageAbout',
                                 'master',
                                 'Edited page About',
                                 @pr_body,
                                 @reviewers).returns('http://example.com')

    # Act
    result = @page_service.save_page_update('about.md', 'About', '# hello', nil, @pr_body, @reviewers)

    assert_equal 'http://example.com', result.pull_request_url
    assert_equal 'sha', result.github_ref
  end

  private

  def create_page_model(parameters)
    page_model = Page.new
    page_model.title = parameters[:title]
    page_model.permalink = parameters[:permalink]
    page_model.contents = parameters[:contents]
    page_model.github_ref = parameters[:github_ref]
    page_model
  end
end
