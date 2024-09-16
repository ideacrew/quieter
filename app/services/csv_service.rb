class CsvService
  include Singleton

  def csv_for_project(org, repo, start_sha, end_sha)
    main_project_commits = GithubService.get_sha_between(org,repo,start_sha,end_sha)
    gem_differences = GemVersionService.extract_gem_differences(org,repo,start_sha,end_sha)
    other_prs = {}
    gem_differences.each_pair do |gd,vs|
      gem_commits = GithubService.get_sha_between(org,gd,vs[:earlier],vs[:later])
      gem_prs = GithubService.get_pr_for_sha(org,gd,gem_commits)
      if gem_prs.any?
        other_prs[gd] = gem_prs
      end
    end
    prs = GithubService.get_pr_for_sha(org,repo,main_project_commits)
    csv_string = GithubService.format_pr_set_for_download(org, repo, prs, other_prs)
  end

  def security_csv_for_project(org, repo)
    vulnerabilities = GithubService.get_vulnerabilities(org,repo)
    csv_string = GithubService.format_vulnerabilities_for_download(vulnerabilities)
  end

  class << self
    delegate :csv_for_project, to: :instance
    delegate :security_csv_for_project, to: :instance
  end
end