# frozen_string_literal: true

require_relative '../factories/page_factory'

module Services
  ##
  # This class contains all operations related to pages on a Jekyll website
  class PageService < BaseEditingService
    def initialize(repo_name, access_token)
        @github_service = GithubService.new(repo_name, access_token)
        @page_factory = PageFactory.new
    end

    def get_markdown_page(file_path, pr_body = nil)
      if pr_body
        open_prs = @github_service.get_open_pull_requests_with_body(pr_body)
        if open_prs.length > 0
          pr_files = @github_service.get_pr_files(open_prs[0][:number])
          markdown_file = pr_files.find { |file| file.end_with?('.md') }
          if markdown_file
            ref = @github_service.get_ref_from_contents_url(markdown_file[:contents_url])
            text_contents = @github_service.get_text_contents_from_file(file_path, ref)
            return @page_factory.create_page(text_contents, ref)
          end
        end
      end

      text_contents = @github_service.get_text_contents_from_file(file_path)
      @page_factory.create_page(text_contents, nil)
    end

    def save_page_update(file_path, page_title, file_contents, ref = nil, pr_body = '', reviewers = [])
      if ref
        ref_name = @github_service.get_ref_name_by_sha(ref)
        sha_base_tree = @github_service.get_base_tree_for_branch(ref)
    
        new_tree_sha = create_new_tree(file_contents, page_title, file_path, sha_base_tree)
        @github_service.commit_and_push_to_repo("Edited page #{page_title}", new_tree_sha, ref, ref_name)
      else
        branch_name = "editPage#{post_title.gsub(/\s+/, '')}"
        ref_name = "heads/#{branch_name}"

        master_head_sha = @github_service.get_master_head_sha
        sha_base_tree = @github_service.get_base_tree_for_branch(master_head_sha)

        @github_service.create_ref_if_necessary(ref_name, master_head_sha)
        new_tree_sha = create_new_tree(file_contents, page_title, file_path, sha_base_tree)
    
        @github_service.commit_and_push_to_repo("Edited page #{page_title}", new_tree_sha, master_head_sha, ref_name)
        @github_service.create_pull_request(branch_name, 'master', "Edited page #{post_title}",
                                            pr_body,
                                            reviewers)
      end
    end
  end
end
