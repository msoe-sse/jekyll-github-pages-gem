# frozen_string_literal: true

require_relative '../test_helper'

##
# Test class for the GithubService class
class GithubServiceTest < BaseGemTest
  def setup
    @repo_name = 'msoe-sg/test-jekyll-site'
    @github_service = Services::GithubService.new(@repo_name, 'auth_token')
  end

  def test_get_master_head_sha_should_return_the_sha_of_the_head_of_master
    # Arrange
    Octokit::Client.any_instance.expects(:ref).with(@repo_name, 'heads/master')
                   .returns(object: { sha: 'master head sha' })

    # Act
    result = @github_service.get_master_head_sha

    # Assert
    assert_equal 'master head sha', result
  end

  def test_get_base_tree_for_branch_should_return_the_sha_of_the_base_tree_for_a_branch
    # Arrange
    Octokit::Client.any_instance.expects(:commit).with(@repo_name, 'master head sha')
                   .returns(commit: { tree: { sha: 'base tree sha' } })

    # Act
    result = @github_service.get_base_tree_for_branch('master head sha')

    # Assert
    assert_equal 'base tree sha', result
  end

  def test_create_text_blob_should_create_a_new_blob_in_the_jekyll_website_repo_and_return_the_sha_of_the_blob
    # Arrange
    Octokit::Client.any_instance.expects(:create_blob)
                   .with(@repo_name, 'my text')
                   .returns('blob sha')

    # Act
    result = @github_service.create_text_blob('my text')

    # Assert
    assert_equal 'blob sha', result
  end

  def test_create_base64_encoded_blob_should_create_a_new_blob_in_the_jekyll_website_repo_and_return_the_sha_of_the_blob
    # Arrange
    Octokit::Client.any_instance.expects(:create_blob)
                   .with(@repo_name, 'my content', 'base64')
                   .returns('blob sha')

    # Act
    result = @github_service.create_base64_encoded_blob('my content')

    # Assert
    assert_equal 'blob sha', result
  end

  def test_create_new_tree_with_blobs_should_create_a_new_tree_in_the_jekyll_website_repo_and_return_the_sha_of_the_tree
    # Arrange
    file_information = [{ path: 'filename1.md', blob_sha: 'blob1 sha' },
                        { path: 'filename2.md', blob_sha: 'blob2 sha' }]
    Octokit::Client.any_instance.expects(:create_tree)
                   .with(@repo_name,
                         [create_blob_info_hash(file_information[0][:path], file_information[0][:blob_sha]),
                          create_blob_info_hash(file_information[1][:path], file_information[1][:blob_sha])],
                         base_tree: 'base tree sha').returns(sha: 'new tree sha')

    # Act
    result = @github_service.create_new_tree_with_blobs(file_information, 'base tree sha')

    # Assert
    assert_equal 'new tree sha', result
  end

  def test_commit_and_push_to_repo_should_create_a_commit_and_push_the_commit_up_to_the_jekyll_website_repo
    # Arrange
    Octokit::Client.any_instance.expects(:create_commit)
                   .with(@repo_name,
                         'Created post Test Post', 'new tree sha', 'master head sha').returns(sha: 'new commit sha')
    Octokit::Client.any_instance.expects(:update_ref)
                   .with(@repo_name, 'heads/createPostTestPost', 'new commit sha').once

    # Act
    @github_service.commit_and_push_to_repo('Created post Test Post', 'new tree sha',
                                            'master head sha', 'heads/createPostTestPost')

    # No Assert - taken care of with mocha mock setups
  end

  def test_create_pull_request_should_open_a_new_pull_request_for_the_jekyll_website_repo
    # Arrange
    pr_body = 'This pull request was opened automatically by the website-editor.'
    reviewers = ['reviewer']
    Octokit::Client.any_instance.expects(:create_pull_request)
                   .with(@repo_name,
                         'master',
                         'createPostTestPost',
                         'Created Post Test Post',
                         pr_body).returns(number: 1)
    Octokit::Client.any_instance.expects(:request_pull_request_review)
                   .with(@repo_name, 1, reviewers: reviewers).once

    # Act
    @github_service.create_pull_request('createPostTestPost', 'master',
                                        'Created Post Test Post',
                                        pr_body,
                                        reviewers)

    # No Assert - taken care of with mocha mock setups
  end

  def test_create_ref_if_necessary_should_not_create_a_new_branch_if_the_branch_already_exists
    # Arrange
    Octokit::Client.any_instance.expects(:ref)
                   .with(@repo_name, 'branchName')
                   .returns('my ref')

    Octokit::Client.any_instance.expects(:create_ref)
                   .with(@repo_name, 'branchName', 'master head sha')
                   .returns('sample response').never

    # Act
    @github_service.create_ref_if_necessary('branchName', 'master head sha')

    # No Assert - taken care of with mocha mock setups
  end

  def test_create_ref_if_necessary_should_create_a_new_branch_if_the_branch_doesnt_exist
    # Arrange
    Octokit::Client.any_instance.expects(:ref)
                   .with(@repo_name, 'branchName')
                   .raises(Octokit::NotFound)

    Octokit::Client.any_instance.expects(:create_ref)
                   .with(@repo_name, 'branchName', 'master head sha')
                   .returns('sample response').once

    # Act
    @github_service.create_ref_if_necessary('branchName', 'master head sha')

    # No Assert - taken care of with mocha mock setups
  end

  def test_get_ref_name_by_sha_should_return_the_properly_formatted_ref_name_from_octokit
    # Arrange
    response = [
      {
        ref: 'refs/heads/branch1',
        object: {
          sha: 'sha 1'
        }
      },
      {
        ref: 'refs/heads/branch2',
        object: {
          sha: 'sha 2'
        }
      },
      {
        ref: 'refs/heads/branch3',
        object: {
          sha: 'sha 3'
        }
      }
    ]

    Octokit::Client.any_instance.expects(:refs).with(@repo_name).returns(response)

    # Act
    result = @github_service.get_ref_name_by_sha('sha 2')

    # Assert
    assert_equal 'heads/branch2', result
  end

  def test_get_text_contents_from_file_should_return_contents_from_default_branch_when_not_given_ref
    # Arrange
    file_path = '_posts/mypost.md'
    contents = create_dummy_api_resource(path: file_path, content: 'post base 64 content')

    Octokit::Client.any_instance.expects(:contents).with(@repo_name, path: file_path).returns(contents)
    Base64.expects(:decode64).with('post base 64 content').returns('post content')

    # Act
    result = @github_service.get_text_contents_from_file(file_path)

    # Assert
    assert_equal 'post content', result
  end

  def test_get_text_contents_from_file_should_return_contents_from_branch_when_given_ref
    # Arrange
    ref = 'ref'
    file_path = '_posts/mypost.md'
    contents = create_dummy_api_resource(path: file_path, content: 'post base 64 content')

    Octokit::Client.any_instance.expects(:contents).with(@repo_name, path: file_path, ref: ref).returns(contents)
    Base64.expects(:decode64).with('post base 64 content').returns('post content')

    # Act
    result = @github_service.get_text_contents_from_file(file_path, ref)

    # Assert
    assert_equal 'post content', result
  end

  def test_get_contents_from_path_should_return_github_contents_response_when_given_valid_path
    # Arrange
    file_path = '_posts/mypost.md'
    contents = create_dummy_api_resource(path: file_path, content: 'post base 64 content')

    Octokit::Client.any_instance.expects(:contents).with(@repo_name, path: file_path).returns(contents)

    # Act
    result = @github_service.get_contents_from_path(file_path)

    # Assert
    assert_equal contents, result
  end

  def test_get_open_pull_requests_with_body_should_return_all_pull_requests_matching_given_body
    # Arrange
    open_pull_requests = [
      create_pull_request_hash('andy-wojciechowski', 'my pr body', 1),
      create_pull_request_hash('GFELMING133', 'my pr body', 2),
      create_pull_request_hash('andy-wojciechowski', 'my pr body 2', 3),
      create_pull_request_hash('Joe-Weller', 'my pr body', 4),
      create_pull_request_hash('andy-wojciechowski', 'my pr body', 5)
    ]

    Octokit::Client.any_instance.expects(:pull_requests).with(@repo_name, state: 'open').returns(open_pull_requests)
    Octokit::Client.any_instance.expects(:user).returns({ login: 'andy-wojciechowski' }).at_least(1)

    # Act
    result = @github_service.get_open_pull_requests_with_body('my pr body')

    # Assert
    assert_equal 2, result.length

    assert_equal open_pull_requests[0], result[0]
    assert_equal open_pull_requests[4], result[1]
  end

  def test_get_pr_files_should_return_pull_request_files_when_given_valid_pr_number
    # Arrange
    pr_files = [
      create_pull_request_file_hash('myBranch', 'post1.md'),
      create_pull_request_file_hash('myBranch', 'post2.md'),
      create_pull_request_file_hash('myBranch', 'post3.md')
    ]

    pr_number = 1

    Octokit::Client.any_instance.expects(:pull_request_files).with(@repo_name, pr_number).returns(pr_files)

    # Act
    result = @github_service.get_pr_files(1)

    # Assert
    assert_equal pr_files, result
  end

  def test_get_ref_from_contents_url_should_return_ref_given_valid_contents_url
    # Arrange
    ref = 'myref'
    contents_url = "http://example.com?ref=#{ref}"

    # Act
    result = @github_service.get_ref_from_contents_url(contents_url)

    # Assert
    assert_equal ref, result
  end

  private

  def create_blob_info_hash(file_path, blob_sha)
    { path: file_path,
      mode: '100644',
      type: 'blob',
      sha: blob_sha }
  end

  def create_commit_hash(date, login)
    # For more information on how this hash was created see:
    # https://developer.github.com/v3/repos/commits/#list-commits-on-a-repository
    {
      commit: {
        committer: {
          date: date
        }
      },
      author: {
        login: login
      }
    }
  end
end
