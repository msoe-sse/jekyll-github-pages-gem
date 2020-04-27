# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../../test_helper'
require_relative '../../../lib/services/post_services/post_editing_service'
require_relative '../../../lib/models/post_image_manager'

class PostEditingServiceTest < BaseGemTest
  def setup
    @post_editing_service = Services::PostEditingService.new('user', 'password')
    @pr_body = 'This pull request was opened automatically by the jekyll website editor.'
    @reviewers = ['reviewer']
  end

  def test_edit_post_should_commit_edits_to_an_existing_post_up_to_the_jekyll_website_Github_repo
    # Arrange
    Services::GithubService.any_instance.expects(:get_master_head_sha).returns('master head sha')
    Services::GithubService.any_instance.expects(:get_base_tree_for_branch)
                           .with('master head sha').returns('master tree sha')
    Services::GithubService.any_instance.expects(:create_ref_if_necessary)
                           .with('heads/editPostTestPost', 'master head sha').once
    Services::GithubService.any_instance.expects(:create_text_blob).with('# hello').returns('post blob sha')
    Services::GithubService.any_instance.expects(:create_new_tree_with_blobs)
                           .with([create_file_info_hash('existing post.md', 'post blob sha')], 'master tree sha')
                           .returns('new tree sha')
    Services::GithubService.any_instance.expects(:commit_and_push_to_repo)
                           .with('Edited post TestPost', 'new tree sha',
                                 'master head sha', 'heads/editPostTestPost').once
    Services::GithubService.any_instance.expects(:create_pull_request)
                           .with('editPostTestPost',
                                 'master',
                                 'Edited Post TestPost',
                                 @pr_body,
                                 @reviewers).once

    PostImageManager.instance.expects(:clear).once

    # Act
    @post_editing_service.edit_post('# hello', 'TestPost', 'existing post.md', @pr_body, @reviewers)

    # No Assert - taken care of with mocha mock setups
  end

  def test_edit_post_should_should_create_a_valid_branch_name_if_the_post_title_has_whitespace
    # Arrange
    Services::GithubService.any_instance.expects(:get_master_head_sha).returns('master head sha')
    Services::GithubService.any_instance.expects(:get_base_tree_for_branch)
                           .with('master head sha').returns('master tree sha')
    Services::GithubService.any_instance.expects(:create_ref_if_necessary)
                           .with('heads/editPostTestPost', 'master head sha').once
    Services::GithubService.any_instance.expects(:create_text_blob).with('# hello').returns('post blob sha')
    Services::GithubService.any_instance.expects(:create_new_tree_with_blobs)
                           .with([create_file_info_hash('existing post.md', 'post blob sha')], 'master tree sha')
                           .returns('new tree sha')
    Services::GithubService.any_instance.expects(:commit_and_push_to_repo)
                           .with('Edited post Test Post', 'new tree sha',
                                 'master head sha', 'heads/editPostTestPost').once
    Services::GithubService.any_instance.expects(:create_pull_request)
                           .with('editPostTestPost',
                                 'master',
                                 'Edited Post Test Post',
                                 @pr_body,
                                 @reviewers).once

    PostImageManager.instance.expects(:clear).once

    # Act
    @post_editing_service.edit_post('# hello', 'Test Post', 'existing post.md', @pr_body, @reviewers)

    # No Assert - taken care of with mocha mock setups
  end

  def test_edit_post_should_upload_any_images_if_any_exist_in_the_PostImageManager
    # Arrange
    test_markdown = "# hello\r\n![My File.jpg](/assets/img/My File.jpg)"

    mock_uploader = create_mock_uploader('post_image-My Image 1.jpg', 'cache 1',
                                         create_mock_carrierware_file('C:\post_image-My Image 1.jpg'))
    post_image_uploader = create_post_image_uploader('My Image 1.jpg', mock_uploader)

    Services::KramdownService.any_instance.expects(:get_image_filename_from_markdown)
                             .with('My Image 1.jpg', test_markdown).returns('My Image 1.jpg')

    image_blob_sha = mock_image_blob_and_return_sha(post_image_uploader)
    PostImageManager.instance.expects(:uploaders).returns([post_image_uploader])
    PostImageManager.instance.expects(:clear).once

    Services::GithubService.any_instance.expects(:get_master_head_sha).returns('master head sha')
    Services::GithubService.any_instance.expects(:get_base_tree_for_branch)
                           .with('master head sha').returns('master tree sha')
    Services::GithubService.any_instance.expects(:create_ref_if_necessary)
                           .with('heads/editPostTestPost', 'master head sha').once
    Services::GithubService.any_instance.expects(:create_text_blob).with(test_markdown).returns('post blob sha')
    Services::GithubService.any_instance.expects(:create_new_tree_with_blobs)
                           .with([create_file_info_hash('existing post.md', 'post blob sha'),
                                  create_file_info_hash('assets/img/My Image 1.jpg', image_blob_sha)],
                                 'master tree sha')
                           .returns('new tree sha')
    Services::GithubService.any_instance.expects(:commit_and_push_to_repo)
                           .with('Edited post Test Post', 'new tree sha',
                                 'master head sha', 'heads/editPostTestPost').once
    Services::GithubService.any_instance.expects(:create_pull_request)
                           .with('editPostTestPost',
                                 'master',
                                 'Edited Post Test Post',
                                 @pr_body,
                                 @reviewers).once

    # Act
    @post_editing_service.edit_post(test_markdown, 'Test Post', 'existing post.md', @pr_body, @reviewers)

    # No Assert - taken care of with mocha mock setups
  end
end
