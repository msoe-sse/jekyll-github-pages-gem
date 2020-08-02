# frozen_string_literal: true

require 'octokit'
require 'base64'
require 'date'
require 'cgi'

module Services
  ##
  # This class contains all operations involving interacting with the GitHub API
  class GithubService
    def initialize(full_repo_name, access_token)
      @full_repo_name = full_repo_name
      @client = Octokit::Client.new(access_token: access_token)
    end

    ##
    # This method gets the sha of the commit at the head of master in a Jekyll website repo
    def get_master_head_sha
      @client.ref(@full_repo_name, 'heads/master')[:object][:sha]
    end

    ##
    # This method gets the sha of the base tree for a given branch in a Jekyll website repo
    #
    # Params
    # +head_sha+::the sha of the head of a certain branch
    def get_base_tree_for_branch(head_sha)
      @client.commit(@full_repo_name, head_sha)[:commit][:tree][:sha]
    end

    ##
    # This method create a new blob in a Jekyll website repo with text content
    #
    # Params
    # +text+::the text content to create a blob for
    def create_text_blob(text)
      @client.create_blob(@full_repo_name, text)
    end

    ##
    # This method creates a new blob in a Jekyll website with base 64 encoded content
    #
    # Params
    # +content+::the base 64 encoded content to create a blob for
    def create_base64_encoded_blob(content)
      @client.create_blob(@full_repo_name, content, 'base64')
    end

    ##
    # This method creates a new tree in a Jekyll website repo and returns the tree's sha.
    # The method assumes that the paths passed into the method have corresponding blobs
    # created for the files
    #
    # Params:
    # +file_information+::an array of hashes containing the file path and the blob sha for a file
    # +sha_base_tree+::the sha of the base tree
    def create_new_tree_with_blobs(file_information, sha_base_tree)
      blob_information = []
      file_information.each do |file|
        # This mode property on this hash represents the file mode for a GitHub tree.
        # The mode is 100644 for a file blob. See https://developer.github.com/v3/git/trees/ for more information
        blob_information << { path: file[:path],
                              mode: '100644',
                              type: 'blob',
                              sha: file[:blob_sha] }
      end
      @client.create_tree(@full_repo_name, blob_information, base_tree: sha_base_tree)[:sha]
    end

    ##
    # This method commits and pushes a tree to a Jekyll website repo
    #
    # Params:
    # +commit_message+::the message for the new commit
    # +tree_sha+::the sha of the tree to commit
    # +head_sha+::the sha of the head to commit from
    def commit_and_push_to_repo(commit_message, tree_sha, head_sha, ref_name)
      sha_new_commit = @client.create_commit(@full_repo_name, commit_message, tree_sha, head_sha)[:sha]
      @client.update_ref(@full_repo_name, ref_name, sha_new_commit)
    end

    ##
    # This method creates a pull request for a branch in a Jekyll website repo
    #
    # Params:
    # +source_branch+::the source branch for the PR
    # +base_branch+::the base branch for the PR
    # +pr_title+::the title for the PR
    # +pr_body+::the body for the PR
    # +reviewers+::an array of pull request reviewers for the PR
    def create_pull_request(source_branch, base_branch, pr_title, pr_body, reviewers)
      pull_number = @client.create_pull_request(@full_repo_name, base_branch, source_branch, pr_title, pr_body)[:number]
      @client.request_pull_request_review(@full_repo_name, pull_number, reviewers: reviewers)
    end

    ##
    # This method will create a branch in a Jekyll website repo
    # if it already doesn't exist
    #
    # Params:
    # +ref_name+:: the name of the branch to create if necessary
    # +master_head_sha+:: the sha representing the head of master
    def create_ref_if_necessary(ref_name, master_head_sha)
      @client.ref(@full_repo_name, ref_name)
    rescue Octokit::NotFound
      @client.create_ref(@full_repo_name, ref_name, master_head_sha)
    end

    ##
    # This method will fetch a GitHub's ref name given it's sha identifier.
    # It will also strip off the starting refs portion of the name
    #
    # Params:
    # +ref_sha+:: the sha of the ref to fetch
    def get_ref_name_by_sha(ref_sha)
      ref_response = @client.refs(@full_repo_name).find { |x| x[:object][:sha] == ref_sha }
      ref_response[:ref].match(%r{refs/(.*)}).captures.first
    end
    
    ##
    # This method will fetch and decode contents of a given file with text contents on GitHub.
    # By default, it will fetch the file contents from the master branch unless a ref to a branch
    # is supplied
    #
    # Params:
    # +file_path+::the path to a file in a GitHub repo
    # +ref+::an optional ref to a branch to fetch the file from
    def get_text_contents_from_file(file_path, ref = nil)
      api_contents = nil
      if ref 
        api_contents = @client.contents(@full_repo_name, path: file_path, ref: ref)
      else
        api_contents = @client.contents(@full_repo_name, path: file_path)
      end
      Base64.decode64(api_contents.content).dup.force_encoding('UTF-8')
    end
    
    ##
    # This method will fetch the GitHub contents for a given file on GitHub via the GitHub
    # contents API. The full response from the API will be returned
    #
    # Params:
    # +path+::the path to a file in a GitHub repo
    def get_contents_from_path(path)
      @client.contents(@full_repo_name, path: path)
    end
    
    ##
    # This method will fetch all open pull requests for the current user matching a specific PR body
    #
    # Params:
    # +pull_request_body+::the body of the PR to look for
    def get_open_pull_requests_with_body(pull_request_body)
      open_pull_requests = @client.pull_requests(@full_repo_name, state: 'open')
      open_pull_requests.select { |x| x[:body] == pull_request_body && x[:user][:login] == @client.user[:login] }
    end
    
    ##
    # This method will fetch all pull request files for a given pull request
    #
    # Params:
    # +pr_number+::the pull request number for the pull request to get all files for
    def get_pr_files(pr_number)
      @client.pull_request_files(@full_repo_name, pr_number)
    end
    
    ##
    # Parses the URL for a file's contents to determine the ref of the file
    # The ref is used to determine what branch the file is located on
    #
    # Params:
    # +contents_url+::the contents url for a file in a GitHub repo
    def get_ref_from_contents_url(contents_url)
      contents_url_params = CGI.parse(contents_url)

      # The CGI.parse method returns a hash with the key being the URL and the value being an array of
      # URI parameters so in order to get the ref we need to grab the first value in the hash and the first
      # URI parameter in the first hash value
      contents_url_params.values.first.first
    end
  end
end
