require_relative '../factories/post_factory'
require 'kramdown_service'

module Services
  class PostService < BaseEditingService
    def initialize(repo_name, access_token)
      super(repo_name, access_token)
      @post_factory = Factories::PostFactory.new
      @kramdown_service = Services::KramdownService.new
    end
    
    ##
    # This method fetches all the markdown contents of all the posts on a Jekyll website
    # that have been written and returns a list of models representing a Post.
    def get_all_posts
      result = []
      api_posts = @github_service.get_contents_from_path('_posts')
      api_posts.each do | api_post |
        post_text_contents = @github_service.get_text_content_from_file(api_post.path)
        post_model = @post_factory.create_post(post_text_contents, api_post.path, nil)
        image_paths = @kramdown_service.get_all_image_paths(post_model.contents)
        
        images = []
        image_paths.each do | image_path |
          image_content = @github_service.get_contents_from_path(image_path)
          images << create_post_image(image_path, image_content.content)
        end
        
        post_model.images = images
        
        result << post_model
      end
      result
    end
    
    ##
    # This method fetches all of the posts that have been written but have not been merged into master yet
    #
    # Params
    # +pr_body+::the pr body for the posts in PR
    def get_all_posts_in_pr(pr_body)
      result = []
      pull_requests = @github_service.get_open_pull_requests_with_body(pr_body)
      pull_requests.each do | pull_request |
        pull_request_files = @github_service.get_pr_files(pull_request[:number])

        post = nil
        images = []
        pull_request_files.each do | pull_request_file |
          ref = @github_service.get_ref_from_contents_url(pull_request_file[:contents_url])
          pr_file_contents = @github_service.get_contents_from_path(pull_request_file[:filename], ref)

          if pull_request_file[:filename].end_with?('.md')
            post_text_contents = @github_service.get_text_content_from_file(pr_file_contents.path, ref)
            post = @post_factory.create_post(post_text_contents, pr_file_contents.path, ref)
            result << post
          else
            images << create_post_image(pr_file_contents.path, pr_file_contents.content)
          end
        end

        post.images = images
      end
      result
    end
    
    ##
    # This method fetches a single post from a Jekyll website given a post title
    # and returns a Post model
    #
    # Params:
    # +title+:: A title of a Jekyll website post
    # +ref+::a sha for a ref indicating the head of a branch a post is pushed to on the GitHub server
    def get_post_by_title(title, ref)
      result = nil
      result = get_all_posts_in_pr.find { |x| x.title == title } if ref
      result = get_all_posts.find { |x| x.title == title } unless ref
      result&.images&.each { |x| PostImageManager.instance.add_downloaded_image(x) }
      result
    end

    ##
    # This method submits a new post to GitHub by checking out a new branch for the post,
    # if the branch already doesn't exist. Commiting and pushing the markdown and any photos
    # attached to the post to the branch. And then finally opening a pull request into master
    # for the new post.
    #
    # Params
    # +oauth_token+::a user's oauth access token
    # +post_markdown+:: the markdown contents of a post
    # +pull_request_body+::an optional pull request body for the post, it will be blank if nothing is provided
    # +reviewers+:: an optional list of reviewers for the post PR
    def create_post(post_markdown, post_title, pull_request_body = '', reviewers = [])
      # This ref_name variable represents the branch name
      # for creating a post. At the end we strip out all of the whitespace in
      # the post_title to create a valid branch name
      branch_name = "createPost#{post_title.gsub(/\s+/, '')}"
      ref_name = "heads/#{branch_name}"
  
      master_head_sha = @github_service.get_master_head_sha
      sha_base_tree = @github_service.get_base_tree_for_branch(master_head_sha)
  
      @github_service.create_ref_if_necessary(ref_name, master_head_sha)
  
      new_post_path = create_new_filepath_for_post(post_title)
      new_tree_sha = create_new_tree(post_markdown, post_title, new_post_path, sha_base_tree)
  
      @github_service.commit_and_push_to_repo("Created post #{post_title}",
                                              new_tree_sha, master_head_sha, ref_name)
      @github_service.create_pull_request(branch_name, 'master', "Created Post #{post_title}",
                                          pull_request_body,
                                          reviewers)
  
      PostImageManager.instance.clear
    end

    ##
    # This method submits changes to an existing post to GitHub by checking out a new branch for the post,
    # if the branch already doesn't exist. Commiting and pushing the markdown changes and any added photos
    # for the existing post to the branch. And the finally opening a pull request into master for the new post.
    #
    # Params
    # +post_markdown+::the modified markdown to submit
    # +post_title+::the title for the existing post
    # +existing_post_file_path+::the file path to the existing post on GitHub
    # +pull_request_body+::an optional pull request body for the post, it will be blank if nothing is provided
    # +reviewers+:: an optional list of reviewers for the post PR
    def edit_post(post_markdown, post_title, existing_post_file_path, pull_request_body = '', reviewers = [])
      # This ref_name variable represents the branch name
      # for editing a post. At the end we strip out all of the whitespace in
      # the post_title to create a valid branch name
      branch_name = "editPost#{post_title.gsub(/\s+/, '')}"
      ref_name = "heads/#{branch_name}"
  
      master_head_sha = @github_service.get_master_head_sha
      sha_base_tree = @github_service.get_base_tree_for_branch(master_head_sha)
  
      @github_service.create_ref_if_necessary(ref_name, master_head_sha)
      new_tree_sha = create_new_tree(post_markdown, post_title, existing_post_file_path, sha_base_tree)
  
      @github_service.commit_and_push_to_repo("Edited post #{post_title}", new_tree_sha, master_head_sha, ref_name)
      @github_service.create_pull_request(branch_name, 'master', "Edited Post #{post_title}",
                                          pull_request_body,
                                          reviewers)
  
      PostImageManager.instance.clear
    end

    ##
    # This method submits changes to a post that is already in PR, commiting and pushing the markdown changes
    # and any added photos to the branch. Since the post is in PR these changes will be a PR updated to the given branch
    #
    # Params:
    # +post_markdown+::the modified markdown to submit
    # +post_title+::the title for the existing post
    # +existing_post_file_path+::the file path to the existing post on GitHub
    # +ref+::the ref to update
    def edit_post_in_pr(post_markdown, post_title, existing_post_file_path, ref)
      ref_name = @github_service.get_ref_name_by_sha(ref)
      sha_base_tree = @github_service.get_base_tree_for_branch(ref)
  
      new_tree_sha = create_new_tree(post_markdown, post_title, existing_post_file_path, sha_base_tree)
      @github_service.commit_and_push_to_repo("Edited post #{post_title}", new_tree_sha, ref, ref_name)
  
      PostImageManager.instance.clear
    end

    private
    
    def create_new_filepath_for_post(post_title)
      "_posts/#{DateTime.now.strftime('%Y-%m-%d')}-#{post_title.gsub(/\s+/, '')}.md"
    end

    def create_post_image(filename, contents)
      result = PostImage.new
      result.filename = filename
      result.contents = contents
      result
    end
  end
end