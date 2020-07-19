# frozen_string_literal: true

require_relative '../test_helper'

##
# Test Class for the PostService class
class PostServiceTest < BaseGemTest
    def setup
      @post_service = Services::PostService.new('msoe-sg/test-jekyll-site', 'auth_token')
      @pr_body = 'This pull request was opened automatically by the jekyll website editor.'
      @reviewers = ['reviewer']
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
  
      Services::GithubService.any_instance.expects(:get_contents_from_path)
                             .with('_posts')
                             .returns([post1, post2, post3])
      Services::GithubService.any_instance.expects(:contents)
                     .with('assets/img/My File1.jpg')
                     .returns(image1_content)
      Services::GithubService.any_instance.expects(:contents)
                             .with('assets/img/My File2.jpg')
                             .returns(image2_content)
      
      Services::GithubService.any_instance.expects(:get_text_content_from_file)
                             .with('_posts/post1.md')
                             .returns('post 1 text content')
      Services::GithubService.any_instance.expects(:get_text_content_from_file)
                             .with('_posts/post2.md')
                             .returns('post 2 text content')
      Services::GithubService.any_instance.expects(:get_text_content_from_file)
                             .with('_posts/post3.md')
                             .returns('post 3 text content')
  
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
      @post_service.create_post('# hello', 'TestPost', @pr_body, @reviewers)
  
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
      @post_service.create_post('# hello', 'Test Post', @pr_body, @reviewers)
  
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
      @post_service.create_post(test_markdown, 'Test Post', @pr_body, @reviewers)
  
      # No Assert - taken care of with mocha mock setups
    end

    def test_edit_post_should_commit_edits_to_an_existing_post_up_to_the_jekyll_website_github_repo
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
      @post_service.edit_post('# hello', 'TestPost', 'existing post.md', @pr_body, @reviewers)
  
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
      @post_service.edit_post('# hello', 'Test Post', 'existing post.md', @pr_body, @reviewers)
  
      # No Assert - taken care of with mocha mock setups
    end
    
    def test_edit_post_should_upload_any_images_if_any_exist_in_the_post_image_manager
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
      @post_service.edit_post(test_markdown, 'Test Post', 'existing post.md', @pr_body, @reviewers)
  
      # No Assert - taken care of with mocha mock setups
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
      @post_service.edit_post_in_pr('# hello', 'TestPost', 'existing post.md', 'my ref')
  
      # No Assert - taken care of with mocha mock setups
    end
end