# frozen_string_literal: true

# Helper module for Github
# This module contains methods to interact with Github API
# and extract information from PRs
# It uses the Octokit gem to interact with Github
# It uses the ENV['GH_TOKEN'] to authenticate with Github
# @todo split the formatting function into a separate module
module GhHelper
  def okto_singleton
    @okto_singleton ||= Octokit::Client.new(access_token: ENV['GH_TOKEN'])
  end

  def get_sha_between(organization, repo, start_sha, end_sha)
    GithubService.get_sha_between(organization, repo, start_sha, end_sha)
  end

  def get_pr_for_sha(organization, repo, commits)
    GithubService.get_pr_for_sha(organization, repo, commits)
  end

  def get_repos_for_select(organization)
    GithubService.get_repos_for_select(organization)
  end

  def extract_auto_links(organization, repo, body)
    GithubService.extract_auto_links(organization, repo, body)
  end

  def github_rate
    GithubService.github_rate
  end
end
