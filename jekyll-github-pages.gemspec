Gem::Specification.new do |s|
  s.name = 'jekyll-github-pages-gem'
  s.version = "1.0.0"
  s.summary = 'A gem that uses the github API to make edits with a jekyll blog'
  s.files = [
    "Gemfile",
    "lib/services/post_services/base_post_service.rb",
    "lib/services/post_services/post_creation_service.rb",
    "lib/services/post_services/post_editing_service.rb",
    "lib/services/post_services/post_pull_request_editing_service.rb",
    "lib/services/github_service.rb",
    "lib/services/kramdown_service.rb",
    "lib/models/post.rb",
    "lib/models/post_image_manager.rb",
    "lib/uploaders/post_image_uploader.rb",
    "lib/factories/post_factory.rb"

  ]
  s.require_paths = ["lib"]
  s.licenses = ["MIT"]
  s.authors= ['MSOE SSE Web Team']
end

