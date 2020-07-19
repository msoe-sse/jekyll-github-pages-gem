# frozen_string_literal: true

require_relative '../factories/page_factory'

module Services
  ##
  # This class contains all operations related to pages on a Jekyll website
  class PageService
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

    def save_page_update(file_path, file_contents, ref = nil, pr_body = '', reviewers = [])
      if ref
      end
    end
  end
end
