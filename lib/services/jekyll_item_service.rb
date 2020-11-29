# frozen_string_literal: true

require_relative '../utilities/utilities'

module Services
  class JekyllItemService
    extend Utilities
    IDENTIFER_LENGTH = 10
    MAX_BRANCH_LENGTH = 40

    def initialize(repo_name, access_token, item_factory)
      @github_service = GithubService.new(repo_name, access_token)
      raise ArgumentError 'item_factory must be of type BaseFactory' if !(item_factory.is_a? Factories::BaseFactory)
      @item_factory = item_factory
    end
    
    ##
    # This method returns all items from a Jekyll collection that are on the default branch.
    # Note if the items in PR specified items that are in PR will not be returned
    #
    # Params:
    # +collection_name+:: the jekyll collection to return items for
    # +pr_items+:: an optional list of items in the collection that are in PR
    def get_all_jekyll_items_in_collection_from_default_branch(collection_name, pr_items = nil)
      result = []
      api_items = @github_service.get_contents_from_path(collection_name)
      api_items.each do |api_item|
        item_text_contents = @github_service.get_text_contents_from_file(api_item.path)
        jekyll_item = @item_factory.create_jekyll_item(item_text_contents, api_item.path, nil)
        add_to_result = !pr_files && !pr_files.find { |item| item.title == jekyll_item.title }
        result << jekyll_item if add_to_result
      end
      result
    end
    
    ##
    # This method returns all items in a Jekyll collection that are currently in PR.
    # Items that have been added or modified will be returned in one collection and items
    # that have been deleted will be returned in a separate collection
    #
    # Params:
    # +collection_name+::the jekyll collection to return items for
    # +pr_body+:: a PR body that is used for identifying PRs that were created by this gem
    def get_all_jekyll_items_in_collection_and_in_pr(collection_name, pr_body)
      added_or_modified_items_in_pr = []
      deleted_items_in_pr = []

      pull_requests = @github_service.get_open_pull_requests_with_body(pr_body)
      pull_requests.each do |pull_request|
        pull_request_files = @github_service.get_pr_files(pull_request[:number])

        pull_request_files.each do |pull_request_file|
          ref = @github_service.get_ref_from_contents_url(pull_request_file[:contents_url])
          pr_file_contents = @github_service.get_contents_from_path(pull_request_file[:filename], ref)

          if pull_request_file[:filename].end_with?('.md') && pull_request_file[:filename].include?(collection_name)
            item_text_contents = @github_service.get_text_content_from_file(pr_file_contents.path, ref)
            jekyll_item = @item_factory.create_jekyll_item(item_text_contents, pr_file_contents.path, pull_request[:html_url])
            if pull_request_file[:added] == 0 && pull_request_file[:deleted] > 0
              deleted_items_in_pr << jekyll_item
            else
              added_or_modified_items_in_pr << jekyll_item
            end
          end
        end
      end
      {added_or_modified_items_in_pr: added_or_modified_items_in_pr, deleted_items_in_pr: deleted_items_in_pr }
    end
    
    ##
    # Returns a given item from a Jekyll website from the default branch unless a pull request body
    # is specified. In that case then it will return the item from the source branch of the first open
    # pull request matching the given body
    #
    # Params:
    # +file_path+:: the path to the file in a GitHub repository
    # +pr_body+:: an optional parameter indicating the pull request body of any updates to a given item, defaults to nil
    def get_jekyll_item(file_path, pr_body = nil)
      if pr_body
        open_prs = @github_service.get_open_pull_requests_with_body(pr_body)
        unless open_prs.empty?
          pr_files = @github_service.get_pr_files(open_prs[0][:number])
          markdown_file = pr_files.find { |file| file[:filename].end_with?('.md') }
          if markdown_file
            ref = @github_service.get_ref_from_contents_url(markdown_file[:contents_url])
            text_contents = @github_service.get_text_contents_from_file(file_path, ref)
            return @item_factory.create_jekyll_item(text_contents, ref, open_prs[0][:html_url])
          end
        end
      end

      text_contents = @github_service.get_text_contents_from_file(file_path)
      @item_factory.create_jekyll_item(text_contents, nil, nil)
    end
    
    ##
    # Saves a given jekyll item update by updating the item contents and creating a pull request into master
    # if a ref is not given. Otherwise if a ref is supplied it will update the branch matching the given ref without creating a pull request.
    #
    # Params:
    # +file_path+:: the path to the file in a GitHub repository
    # +title+:: the title of the item
    # +file_contents+:: the text contents of the site item
    # +klass+:: the ruby class corresponding to the type of item that is being updated
    # +ref+::an optional branch indicating the page should be updated on a branch that's not the default branch, defaults to nil
    # +pr_body+::an optional pull request body when updating the page on the default branch, defaults to an empty string
    # +reviewers+::an optional array of reviewers for opening a pull request when updating the page on the default branch, defaults to no reviewers
    def save_jekyll_item_update(file_path, title, file_contents, klass, ref = nil, pr_body = '', reviewers = [])
      if ref
        ref_name = @github_service.get_ref_name_by_sha(ref)
        sha_base_tree = @github_service.get_base_tree_for_branch(ref)

        new_tree_sha = create_new_tree(file_contents, title, file_path, sha_base_tree)
        @github_service.commit_and_push_to_repo("Edited #{klass.name} #{title}", new_tree_sha, ref, ref_name)
        nil
      else
        branch_name = "edit#{klass.name}#{title.gsub(/\s+/, '')}#{self.generate_random_string(IDENTIFER_LENGTH)}".slice(0, MAX_BRANCH_LENGTH)
        ref_name = "heads/#{branch_name}"

        master_head_sha = @github_service.get_master_head_sha
        sha_base_tree = @github_service.get_base_tree_for_branch(master_head_sha)

        @github_service.create_ref_if_necessary(ref_name, master_head_sha)
        new_tree_sha = create_new_tree(file_contents, title, file_path, sha_base_tree)

        ref_sha = @github_service.commit_and_push_to_repo("Edited #{klass.name} #{title}", new_tree_sha, master_head_sha, ref_name)
        pull_request_url = @github_service.create_pull_request(branch_name, 'master', "Edited #{klass.name} #{title}",
                                                               pr_body,
                                                               reviewers)
        create_save_page_update_result(ref_sha, pull_request_url, klass)
      end
    end
    
    ##
    # This method submits a new item to GitHub by checking out a new branch for the item,
    # if the branch already doesn't exist. Commiting and pushing the markdown to the branch. 
    # And then finally opening a pull request into master for the new item.
    #
    # Params
    # +markdown+:: the markdown contents of a item
    # +title+:: the title of the item
    # +klass+:: the ruby class corresponding to the type of item that is being updated
    # +collection_name+:: an optional name of a jekyll collection for the item
    # +pull_request_body+::an optional pull request body for the post, it will be blank if nothing is provided
    # +reviewers+:: an optional list of reviewers for the post PR
    def create_jekyll_item(markdown, title, klass, collection_name = nil, pull_request_body = '', reviewers = [])
      branch_name = "create#{klass.name}#{title.gsub(/\s+/, '')}#{self.generate_random_string(IDENTIFER_LENGTH)}".slice(0, MAX_BRANCH_LENGTH)
      ref_name = "heads/#{branch_name}"

      master_head_sha = @github_service.get_master_head_sha
      sha_base_tree = @github_service.get_base_tree_for_branch(master_head_sha)

      @github_service.create_ref_if_necessary(ref_name, master_head_sha)

      new_item_path = @item_factory.create_file_path_for_item(title, collection_name)
      new_tree_sha = create_new_tree(markdown, title, new_item_path, sha_base_tree)

      @github_service.commit_and_push_to_repo("Created #{klass.name} #{title}",
                                              new_tree_sha, master_head_sha, ref_name)
      @github_service.create_pull_request(branch_name, 'master', "Created #{klass.name} #{title}",
                                          pull_request_body,
                                          reviewers)
    end
    
    ##
    # This method will delete a given item from a jekyll website, push that deletion to a new branch,
    # and it will open up a new pull request for the deletion.
    #
    # Params
    # +file_path+:: the file path of the item to delete
    # +title+:: the title of the item to delete
    # +klass+:: the ruby class corresponding to the type of item that is being deleted
    # +pull_request_body+::an optional pull request body for the post, it will be blank if nothing is provided
    # +reviewers+:: an optional list of reviewers for the post PR
    def delete_jekyll_item(file_path, title, klass, pull_request_body = '', reviewers = [])
      branch_name = "delete#{klass.name}#{title.gsub(/\s+/, '')}#{self.generate_random_string(IDENTIFER_LENGTH)}".slice(0, MAX_BRANCH_LENGTH)
      ref_name = "heads/#{branch_name}"

      master_head_sha = @github_service.get_master_head_sha
      @github_service.create_ref_if_necessary(ref_name, master_head_sha)

      @github_service.delete_file(file_path, "Deleted #{klass.name} #{title}", branch_name)
      @github_service.create_pull_request(branch_name, 'master', "Deleted #{klass.name} #{title}",
                                          pull_request_body,
                                          reviewers)
    end

    private

    def create_save_item_update_result(ref_sha, pull_request_url, klass)
      result = klass.new
      result.github_ref = ref_sha
      result.pull_request_url = pull_request_url
      result
    end

    def create_new_tree(markdown, file_path, sha_base_tree)
      file_information = [create_blob_for_item(markdown, file_path)]
      @github_service.create_new_tree_with_blobs(file_information, sha_base_tree)
    end

    def create_blob_for_item(markdown, file_path)
      blob_sha = @github_service.create_text_blob(markdown)
      { path: file_path, blob_sha: blob_sha }
    end
  end
end
