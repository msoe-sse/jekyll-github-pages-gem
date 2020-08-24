# frozen_string_literal: true

require_relative '../factories/page_factory'

module Services
  ##
  # This class contains all operations related to pages on a Jekyll website
  class PageService < BaseEditingService
    def initialize(repo_name, access_token)
      super(repo_name, access_token)
      @page_factory = Factories::PageFactory.new
    end

    ##
    # Returns a given page from a Jekyll website from the default branch unless a pull request body
    # is specified. In that case then it will return the page from the source branch of the first open
    # pull request matching the given body
    #
    # Params:
    # +file_path+:: the path to the file in a GitHub repository
    # +pr_body+:: an optional parameter indicating the pull request body of any updates to a given page, defaults to nil
    def get_markdown_page(file_path, pr_body = nil)
      if pr_body
        open_prs = @github_service.get_open_pull_requests_with_body(pr_body)
        unless open_prs.empty?
          pr_files = @github_service.get_pr_files(open_prs[0][:number])
          markdown_file = pr_files.find { |file| file[:filename].end_with?('.md') }
          if markdown_file
            ref = @github_service.get_ref_from_contents_url(markdown_file[:contents_url])
            text_contents = @github_service.get_text_contents_from_file(file_path, ref)
            return @page_factory.create_page(text_contents, ref, open_prs[0][:html_url])
          end
        end
      end

      text_contents = @github_service.get_text_contents_from_file(file_path)
      @page_factory.create_page(text_contents, nil, nil)
    end

    ##
    # Saves a given page update by updating the page contents and creating a pull request into master
    # if a ref is not given. Otherwise if a ref is supplied it will update the branch matching the given ref without creating a pull request.
    #
    # Params:
    # +file_path+:: the path to the file in a GitHub repository
    # +page_title+:: the title of the page
    # +ref+::an optional branch indicating the page should be updated on a branch that's not the default branch, defaults to nil
    # +pr_body+::an optional pull request body when updating the page on the default branch, defaults to an empty string
    # +reviewers+::an optional array of reviewers for opening a pull request when updating the page on the default branch, defaults to no reviewers
    def save_page_update(file_path, page_title, file_contents, ref = nil, pr_body = '', reviewers = [])
      if ref
        ref_name = @github_service.get_ref_name_by_sha(ref)
        sha_base_tree = @github_service.get_base_tree_for_branch(ref)

        new_tree_sha = create_new_tree(file_contents, page_title, file_path, sha_base_tree)
        @github_service.commit_and_push_to_repo("Edited page #{page_title}", new_tree_sha, ref, ref_name)
        nil
      else
        branch_name = "editPage#{page_title.gsub(/\s+/, '')}"
        ref_name = "heads/#{branch_name}"

        master_head_sha = @github_service.get_master_head_sha
        sha_base_tree = @github_service.get_base_tree_for_branch(master_head_sha)

        @github_service.create_ref_if_necessary(ref_name, master_head_sha)
        new_tree_sha = create_new_tree(file_contents, page_title, file_path, sha_base_tree)

        ref_sha = @github_service.commit_and_push_to_repo("Edited page #{page_title}", new_tree_sha, master_head_sha, ref_name)
        pull_request_url = @github_service.create_pull_request(branch_name, 'master', "Edited page #{page_title}",
                                                               pr_body,
                                                               reviewers)
        create_save_page_update_result(ref_sha, pull_request_url)
      end
    end

    private

    def create_save_page_update_result(ref_sha, pull_request_url)
      result = Page.new
      result.github_ref = ref_sha
      result.pull_request_url = pull_request_url
      result
    end
  end
end
