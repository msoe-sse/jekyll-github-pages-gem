# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../test_helper'
require_relative '../../lib/services/github_service'

##
# Test class for the GithubService class
class GithubServiceTest < BaseGemTest
  def setup
    @repo_name = 'msoe-sg/test-jekyll-site'
    @github_service = Services::GithubService.new(@repo_name, 'auth_token')
  end

  def test_get_all_posts_should_return_all_posts_from_the_jekyll_website
    # Arrange
    post1 = create_dummy_api_resource(path: '_posts/post1.md')
    post2 = create_dummy_api_resource(path: '_posts/post2.md')
    post3 = create_dummy_api_resource(path: '_posts/post3.md')

    post1_content = create_dummy_api_resource(path: '_posts/post1.md', content: 'post 1 base 64 content')
    post2_content = create_dummy_api_resource(path: '_posts/post2.md', content: 'post 2 base 64 content')
    post3_content = create_dummy_api_resource(path: '_posts/post3.md', content: 'post 3 base 64 content')
    image1_content = create_dummy_api_resource(content: 'imagecontents1', path: 'My File1.jpg')
    image2_content = create_dummy_api_resource(content: 'imagecontents2', path: 'My File2.jpg')

    post1_markdown = "#post1\r\n![My Alt Text](/assets/img/My File1.jpg)\r\n![My Alt Text](/assets/img/My File2.jpg)"

    post1_model = create_post_model(title: 'post 1', author: 'Andy Wojciechowski', hero: 'hero 1',
                                    overlay: 'overlay 1', contents: post1_markdown, tags: %w[announcement info])
    post2_model = create_post_model(title: 'post 2', author: 'Grace Fleming', hero: 'hero 2',
                                    overlay: 'overlay 2', contents: '##post2', tags: ['announcement'])
    post3_model = create_post_model(title: 'post 3', author: 'Sabrina Stangler', hero: 'hero 3',
                                    overlay: 'overlay 3', contents: '###post3', tags: ['info'])

    Services::KramdownService.any_instance.expects(:get_all_image_paths).with(post1_markdown)
                             .returns(['assets/img/My File1.jpg', 'assets/img/My File2.jpg'])
    Services::KramdownService.any_instance.expects(:get_all_image_paths).with('##post2').returns([])
    Services::KramdownService.any_instance.expects(:get_all_image_paths).with('###post3').returns([])

    Octokit::Client.any_instance.expects(:contents)
                   .with(@repo_name, path: '_posts')
                   .returns([post1, post2, post3])
    Octokit::Client.any_instance.expects(:contents)
                   .with(@repo_name, path: '_posts/post1.md')
                   .returns(post1_content)
    Octokit::Client.any_instance.expects(:contents)
                   .with(@repo_name, path: '_posts/post2.md')
                   .returns(post2_content)
    Octokit::Client.any_instance.expects(:contents)
                   .with(@repo_name, path: '_posts/post3.md')
                   .returns(post3_content)
    Octokit::Client.any_instance.expects(:contents)
                   .with(@repo_name, path: 'assets/img/My File1.jpg')
                   .returns(image1_content)
    Octokit::Client.any_instance.expects(:contents)
                   .with(@repo_name, path: 'assets/img/My File2.jpg')
                   .returns(image2_content)

    Base64.expects(:decode64).with('post 1 base 64 content').returns('post 1 text content')
    Base64.expects(:decode64).with('post 2 base 64 content').returns('post 2 text content')
    Base64.expects(:decode64).with('post 3 base 64 content').returns('post 3 text content')

    Factories::PostFactory.any_instance.expects(:create_post)
                          .with('post 1 text content', '_posts/post1.md', nil).returns(post1_model)
    Factories::PostFactory.any_instance.expects(:create_post)
                          .with('post 2 text content', '_posts/post2.md', nil).returns(post2_model)
    Factories::PostFactory.any_instance.expects(:create_post)
                          .with('post 3 text content', '_posts/post3.md', nil).returns(post3_model)

    # Act
    result = @github_service.get_all_posts

    # Assert
    assert_equal [post1_model, post2_model, post3_model], result

    assert_equal 2, post1_model.images.length
    assert_post_image('assets/img/My File1.jpg', 'imagecontents1', post1_model.images[0])
    assert_post_image('assets/img/My File2.jpg', 'imagecontents2', post1_model.images[1])

    assert_equal 0, post3_model.images.length
  end

  def test_get_all_posts_in_pr_should_return_all_posts_in_pr
    # Arrange
    pr_body = 'This pull request was opened automatically by the SG website editor.'
    post_content = create_dummy_api_resource(content: 'PR base 64 content', path: 'sample.md')
    image_content = create_dummy_api_resource(content: 'imagecontents', path: 'sample.jpeg')
    post_model = create_post_model(title: 'post', author: 'Andy Wojciechowski', hero: 'hero',
                                   overlay: 'overlay', contents: '#post', tags: %w[announcement info])

    Octokit::Client.any_instance.expects(:pull_requests).with(@repo_name, state: 'open')
                   .returns([create_pull_request_hash('andy-wojciechowski', 'My Pull Request Body', 2),
                             create_pull_request_hash('andy-wojciechowski',
                                                      pr_body, 3)])

    Octokit::Client.any_instance.expects(:pull_request_files).with(@repo_name, 1)
                   .returns([]).never
    Octokit::Client.any_instance.expects(:pull_request_files).with(@repo_name, 2)
                   .returns([]).never
    Octokit::Client.any_instance.expects(:pull_request_files).with(@repo_name, 3).returns([
                                                                                            create_pull_request_file_hash('myref', 'sample.md'),
                                                                                            create_pull_request_file_hash('myref', 'sample.jpeg')
                                                                                          ])

    Octokit::Client.any_instance.expects(:contents)
                   .with(@repo_name, path: 'sample.md', ref: 'myref')
                   .returns(post_content)

    Octokit::Client.any_instance.expects(:contents)
                   .with(@repo_name, path: 'sample.jpeg', ref: 'myref')
                   .returns(image_content)

    Base64.expects(:decode64).with('PR base 64 content').returns('PR content')
    Factories::PostFactory.any_instance.expects(:create_post)
                          .with('PR content', 'sample.md', 'myref').returns(post_model)

    # Act
    result = @github_service.get_all_posts_in_pr(pr_body)

    # Assert
    assert_equal [post_model], result

    assert_equal 1, post_model.images.length
    assert_post_image('sample.jpeg', 'imagecontents', post_model.images.first)
  end

  def test_get_post_by_title_should_return_nil_if_the_post_does_not_exist
    # Arrange
    post1_model = create_post_model(title: 'post 1', author: 'Andy Wojciechowski', hero: 'hero 1',
                                    overlay: 'overlay 1', contents: '#post1', tags: %w[announcement info])
    post2_model = create_post_model(title: 'post 2', author: 'Grace Fleming', hero: 'hero 2',
                                    overlay: 'overlay 2', contents: '##post2', tags: ['announcement'])
    post3_model = create_post_model(title: 'post 3', author: 'Sabrina Stangler', hero: 'hero 3',
                                    overlay: 'overlay 3', contents: '###post3', tags: ['info'])

    @github_service.expects(:get_all_posts).returns([post1_model, post2_model, post3_model])

    # Act
    result = @github_service.get_post_by_title('a very fake post', nil)

    # Assert
    assert_nil result
  end

  def test_get_post_by_title_should_return_a_given_post_by_its_title
    # Arrange
    post1_model = create_post_model(title: 'post 1', author: 'Andy Wojciechowski', hero: 'hero 1',
                                    overlay: 'overlay 1', contents: '#post1', tags: %w[announcement info])
    post2_model = create_post_model(title: 'post 2', author: 'Grace Fleming', hero: 'hero 2',
                                    overlay: 'overlay 2', contents: '##post2', tags: ['announcement'])
    post3_model = create_post_model(title: 'post 3', author: 'Sabrina Stangler', hero: 'hero 3',
                                    overlay: 'overlay 3', contents: '###post3', tags: ['info'])

    @github_service.expects(:get_all_posts).returns([post1_model, post2_model, post3_model])

    # Act
    result = @github_service.get_post_by_title('post 2', nil)

    # Assert
    assert_equal post2_model, result
  end

  def test_get_post_by_title_should_return_nil_if_the_post_does_not_exist_on_a_given_ref
    # Arrange
    post1_model = create_post_model(title: 'post 1', author: 'Andy Wojciechowski', hero: 'hero 1',
                                    overlay: 'overlay 1', contents: '#post1', tags: %w[announcement info])
    post2_model = create_post_model(title: 'post 2', author: 'Grace Fleming', hero: 'hero 2',
                                    overlay: 'overlay 2', contents: '##post2', tags: ['announcement'])
    post3_model = create_post_model(title: 'post 3', author: 'Sabrina Stangler', hero: 'hero 3',
                                    overlay: 'overlay 3', contents: '###post3', tags: ['info'])

    @github_service.expects(:get_all_posts_in_pr).returns([post1_model, post2_model, post3_model])

    # Act
    result = @github_service.get_post_by_title('a very fake post', 'ref')

    # Assert
    assert_nil result
  end

  def test_get_post_by_title_should_return_a_given_post_by_its_title_given_a_ref
    # Arrange
    post1_model = create_post_model(title: 'post 1', author: 'Andy Wojciechowski', hero: 'hero 1',
                                    overlay: 'overlay 1', contents: '#post1', tags: %w[announcement info])
    post2_model = create_post_model(title: 'post 2', author: 'Grace Fleming', hero: 'hero 2',
                                    overlay: 'overlay 2', contents: '##post2', tags: ['announcement'])
    post3_model = create_post_model(title: 'post 3', author: 'Sabrina Stangler', hero: 'hero 3',
                                    overlay: 'overlay 3', contents: '###post3', tags: ['info'])

    @github_service.expects(:get_all_posts_in_pr).returns([post1_model, post2_model, post3_model])

    # Act
    result = @github_service.get_post_by_title('post 2', 'ref')

    # Assert
    assert_equal post2_model, result
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

  private

  def create_dummy_api_resource(parameters)
    resource = DummyApiResource.new
    resource.path = parameters[:path]
    resource.content = parameters[:content]
    resource
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

  def create_pull_request_hash(username, body, number)
    {
      user: {
        login: username
      },
      body: body,
      number: number
    }
  end

  def create_pull_request_file_hash(ref, filename)
    {
      contents_url: "http://example.com?ref=#{ref}",
      filename: filename
    }
  end

  def assert_post_image(filename, contents, actual)
    assert_equal filename, actual.filename
    assert_equal contents, actual.contents
  end

  ##
  # Represents a dummy API resource object from Octokit
  class DummyApiResource
    attr_accessor :path
    attr_accessor :content
  end
end
