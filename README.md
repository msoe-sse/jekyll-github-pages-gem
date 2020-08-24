[![Build Status](https://travis-ci.org/msoe-sg/jekyll-github-pages-gem.svg?branch=master)](https://travis-ci.org/msoe-sg/jekyll-github-pages-gem)

## Setup
1. Follow the instructions from the wiki article [here](https://github.com/msoe-sg/msoe-sg-website/wiki/Environment-Setup) to setup your development environment.
2. Open up a terminal to the folder where you want to clone the repo and run the command `git@github.com:msoe-sg/jekyll-github-pages-gem.git`
3. After run the clone change into the project directory by running the command `cd jekyll-github-pages-gem`
4. Next install the dependencies for the project by running the command `bundle install`
5. Contribute
Our git flow process is typical--we have a master branch that gets released to the public, and feature branches for individual tasks. We don't have a development branch yet since this isn't used in production yet.
If you have questions on how to contribute, please contact admin@msoe-sse.com or msoe.sg.hosting@gmail.com and we will get back to you at our earliest convenience.

## Generating HTML Documentation
To generate HTML documentation for the Gem run the command `rake rdoc` and the HTML will then be available in the `html/` directory in the project.

## Continuous Integration
There are checks that will be performed whenever Pull Requests are opened.  To save time on the build server, please run the tests locally to check for errors that will occur in the CI builds.

1. To run [Rubocop](https://github.com/ashmaroli/rubocop-jekyll), run the command `bundle exec rubocop`. Note the command `bundle exec rubocop -a` will attempt to automatically fix any offenses found by rubocop but some still need to be resolved manually.
2. To run all unit tests, run the command `rake`
