# frozen_string_literal: true

require_relative '../test_helper'

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
    Factories::PageFactory.any_instance.expects(:create_page).with('text contents', nil).returns(page_model)

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
    Factories::PageFactory.any_instance.expects(:create_page).with('text contents', nil).returns(page_model)

    # Act
    result = @page_service.get_markdown_page('about.md', pr_body)

    # Assert
    assert_equal page_model, result
  end

  def test_get_markdown_page_should_return_page_model_from_default_branch_when_first_open_pr_has_no_markdown_files
    # Arrange
    pr_body = 'my body'
    page_model = create_page_model(title: 'About', permalink: '/about/', contents: 'text contents')
    
    Services::GithubService.any_instance.expects(:get_open_pull_requests_with_body).with(pr_body).returns([
        create_pull_request_hash('andy-wojciechowski', pr_body, 1),
        create_pull_request_hash('andy-wojciechowski', pr_body, 2)
    ])
    Services::GithubService.any_instance.expects(:get_pr_files).with(1).returns([
        create_pull_request_file_hash('ref', 'myfile.jpg'),
        create_pull_request_file_hash('ref', 'myfile.csv')
    ])
    Services::GithubService.any_instance.expects(:get_text_contents_from_file).with('about.md').returns('text contents')
    Factories::PageFactory.any_instance.expects(:create_page).with('text contents', nil).returns(page_model)

    # Act
    result = @page_service.get_markdown_page('about.md', pr_body)

    # Assert
    assert_equal page_model, result
  end

  def test_get_markdown_page_should_return_page_model_from_other_branch_when_first_open_pr_has_markdown_files
    # Arrange
    pr_body = 'my body'
    page_model = create_page_model(title: 'About', permalink: '/about/', contents: 'text contents', github_ref: 'ref')
    
    Services::GithubService.any_instance.expects(:get_open_pull_requests_with_body).with(pr_body).returns([
        create_pull_request_hash('andy-wojciechowski', pr_body, 1),
        create_pull_request_hash('andy-wojciechowski', pr_body, 2)
    ])
    Services::GithubService.any_instance.expects(:get_pr_files).with(1).returns([
        create_pull_request_file_hash('ref', 'myfile.jpg'),
        create_pull_request_file_hash('ref', 'page.md'),
        create_pull_request_file_hash('ref', 'otherfile.md')
    ])
    Services::GithubService.any_instance.expects(:get_ref_from_contents_url).with('http://example.com?ref=ref').returns('ref')
    Services::GithubService.any_instance.expects(:get_text_contents_from_file).with('about.md', 'ref').returns('text contents')
    Factories::PageFactory.any_instance.expects(:create_page).with('text contents', 'ref').returns(page_model)

    # Act
    result = @page_service.get_markdown_page('about.md', pr_body)

    # Assert
    assert_equal page_model, result
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
