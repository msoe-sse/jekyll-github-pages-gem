# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../../test_helper'
require_relative '../../../lib/services/post_services/post_pull_request_editing_service'
require_relative '../../../lib/models/post_image_manager'

##
# Test class for the PostPullRequestEditingService class
class PostPullRequestEditingServiceTest < BaseGemTest
  def setup
    @post_pull_request_editing_service = Services::PostPullRequestEditingService.new('user', 'password')
  end

  def test_edit_post_in_pr_should_commit_edits_to_an_existing_post_up_to_the_jekyll_website_github_repo
    # Arrange
    Services::GithubService.any_instance.expects(:get_ref_name_by_sha).returns('heads/createPostTestPost')
    Services::GithubService.any_instance.expects(:get_base_tree_for_branch).with('my ref').returns('master tree sha')
    Services::GithubService.any_instance.expects(:create_text_blob).with('# hello').returns('post blob sha')
    Services::GithubService.any_instance.expects(:create_new_tree_with_blobs)
                           .with([create_file_info_hash('existing post.md', 'post blob sha')], 'master tree sha')
                           .returns('new tree sha')
    Services::GithubService.any_instance.expects(:commit_and_push_to_repo)
                           .with('Edited post TestPost', 'new tree sha',
                                 'my ref', 'heads/createPostTestPost').once

    PostImageManager.instance.expects(:clear).once

    # Act
    @post_pull_request_editing_service.edit_post_in_pr('# hello', 'TestPost', 'existing post.md', 'my ref')

    # No Assert - taken care of with mocha mock setups
  end
end
