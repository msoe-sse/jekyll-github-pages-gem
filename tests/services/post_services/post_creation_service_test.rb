# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../../test_helper'
require_relative '../../../lib/services/post_services/post_creation_service'
require_relative '../../../lib/models/post_image_manager'

##
# Test class for the PostCreationService class
class PostCreationServiceTest < BaseGemTest
  def setup
    @post_creation_service = Services::PostCreationService.new('user', 'password')
    @pr_body = 'This pull request was opened automatically by the jekyll website editor.'
    @reviewers = ['reviewer']
  end

  def test_create_post_should_commit_and_push_a_new_post_up_to_the_jekyll_website_github_repo
    # Arrange
    post_file_path = "_posts/#{DateTime.now.strftime('%Y-%m-%d')}-TestPost.md"

    Services::GithubService.any_instance.expects(:get_master_head_sha).returns('master head sha')
    Services::GithubService.any_instance.expects(:get_base_tree_for_branch)
                           .with('master head sha').returns('master tree sha')
    Services::GithubService.any_instance.expects(:create_ref_if_necessary)
                           .with('heads/createPostTestPost', 'master head sha').once
    Services::GithubService.any_instance.expects(:create_text_blob).with('# hello').returns('post blob sha')
    Services::GithubService.any_instance.expects(:create_new_tree_with_blobs)
                           .with([create_file_info_hash(post_file_path, 'post blob sha')], 'master tree sha')
                           .returns('new tree sha')
    Services::GithubService.any_instance.expects(:commit_and_push_to_repo)
                           .with('Created post TestPost', 'new tree sha',
                                 'master head sha', 'heads/createPostTestPost').once
    Services::GithubService.any_instance.expects(:create_pull_request)
                           .with('createPostTestPost',
                                 'master',
                                 'Created Post TestPost',
                                 @pr_body,
                                 @reviewers).once

    PostImageManager.instance.expects(:clear).once

    # Act
    @post_creation_service.create_post('# hello', 'TestPost', @pr_body, @reviewers)

    # No Assert - taken care of with mocha mock setups
  end

  def test_create_post_should_create_a_valid_branch_name_if_the_post_title_has_whitespace
    # Arrange
    post_file_path = "_posts/#{DateTime.now.strftime('%Y-%m-%d')}-TestPost.md"

    Services::GithubService.any_instance.expects(:get_master_head_sha).returns('master head sha')
    Services::GithubService.any_instance.expects(:get_base_tree_for_branch)
                           .with('master head sha').returns('master tree sha')
    Services::GithubService.any_instance.expects(:create_ref_if_necessary)
                           .with('heads/createPostTestPost', 'master head sha').once
    Services::GithubService.any_instance.expects(:create_text_blob).with('# hello').returns('post blob sha')
    Services::GithubService.any_instance.expects(:create_new_tree_with_blobs)
                           .with([create_file_info_hash(post_file_path, 'post blob sha')], 'master tree sha')
                           .returns('new tree sha')
    Services::GithubService.any_instance.expects(:commit_and_push_to_repo)
                           .with('Created post Test Post', 'new tree sha',
                                 'master head sha', 'heads/createPostTestPost').once
    Services::GithubService.any_instance.expects(:create_pull_request)
                           .with('createPostTestPost',
                                 'master',
                                 'Created Post Test Post',
                                 @pr_body,
                                 @reviewers).once

    PostImageManager.instance.expects(:clear).once

    # Act
    @post_creation_service.create_post('# hello', 'Test Post', @pr_body, @reviewers)

    # No Assert - taken care of with mocha mock setups
  end

  def test_create_post_should_upload_any_images_if_any_exist_in_the_post_image_manager
    # Arrange
    post_file_path = "_posts/#{DateTime.now.strftime('%Y-%m-%d')}-TestPost.md"
    test_markdown = "# hello\r\n![My File.jpg](/assets/img/My Image 1.jpg)"

    mock_uploader1 = create_mock_uploader('post_image-My_Image_1.jpg', 'cache 1',
                                          create_mock_carrierware_file('C:\post_image-My Image 1.jpg'))
    post_image_uploader1 = create_post_image_uploader('My_Image_1.jpg', mock_uploader1)

    mock_uploader2 = create_mock_uploader('post_image-My_Image_2.jpg', 'cache 2',
                                          create_mock_carrierware_file('C:\post_image-My Image 2.jpg'))
    post_image_uploader2 = create_post_image_uploader('My_Image_2.jpg', mock_uploader2)

    Services::KramdownService.any_instance.expects(:get_image_filename_from_markdown)
                             .with('My_Image_1.jpg', test_markdown).returns('My Image 1.jpg')
    Services::KramdownService.any_instance.expects(:get_image_filename_from_markdown)
                             .with('My_Image_2.jpg', test_markdown).returns(nil)

    image_blob_sha1 = mock_image_blob_and_return_sha(post_image_uploader1)
    PostImageManager.instance.expects(:uploaders).returns([post_image_uploader1, post_image_uploader2])
    PostImageManager.instance.expects(:clear).once

    Services::GithubService.any_instance.expects(:get_master_head_sha).returns('master head sha')
    Services::GithubService.any_instance.expects(:get_base_tree_for_branch)
                           .with('master head sha').returns('master tree sha')
    Services::GithubService.any_instance.expects(:create_ref_if_necessary)
                           .with('heads/createPostTestPost', 'master head sha').once
    Services::GithubService.any_instance.expects(:create_text_blob).with(test_markdown).returns('post blob sha')
    Services::GithubService.any_instance.expects(:create_new_tree_with_blobs)
                           .with([create_file_info_hash(post_file_path, 'post blob sha'),
                                  create_file_info_hash('assets/img/My Image 1.jpg', image_blob_sha1)],
                                 'master tree sha')
                           .returns('new tree sha')
    Services::GithubService.any_instance.expects(:commit_and_push_to_repo)
                           .with('Created post Test Post', 'new tree sha',
                                 'master head sha', 'heads/createPostTestPost').once
    Services::GithubService.any_instance.expects(:create_pull_request)
                           .with('createPostTestPost',
                                 'master',
                                 'Created Post Test Post',
                                 @pr_body,
                                 @reviewers).once

    # Act
    @post_creation_service.create_post(test_markdown, 'Test Post', @pr_body, @reviewers)

    # No Assert - taken care of with mocha mock setups
  end
end
