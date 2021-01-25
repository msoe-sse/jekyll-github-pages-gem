# frozen_string_literal: true

require 'yaml'

module Services
  class JekyllDataService
    def initialize(repo_name, access_token)
      @github_service = GithubService.new(repo_name, access_token)
    end

    def get_jekyll_data_as_hash(data_file_name, ref = nil)
      file_path = "_data/#{data_file_name}"
      yaml_content = @github_service.get_text_content_from_file(file_path, ref)
      YAML.load(yaml_content)
    end
  end
end
