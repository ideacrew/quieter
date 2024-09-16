require 'csv'
require 'uri'
require 'async/barrier'
require 'async/semaphore'

class GithubService

  include Singleton

  attr_reader :okto_singleton

  def initialize
    @okto_singleton = Octokit::Client.new(access_token: ENV['GH_TOKEN'])
    @repo_autolinks = Hash.new do |h, k|
      nh = Hash.new do |ch, ck|
        ch[ck] = internal_autolinks_logic(k, ck)
      end
      h[k] = nh
    end
  end

  def get_file_content_at_sha(organization, repo, sha, path)
    r = okto_singleton.contents("#{organization}/#{repo}", :path => path, :ref => sha)
    return nil unless r["content"]
    Base64.decode64(r["content"])
  end

  def get_sha_between(organization, repo, start_sha, end_sha)
    Rails.logger.info "Getting commits for #{organization}/#{repo} between #{start_sha} and #{end_sha}"
    diff = okto_singleton.compare("#{organization}/#{repo}", start_sha, end_sha)
    diff.commits.map { |item| { sha: item.sha, html_url: item.html_url } }
  end

  def get_vulnerabilities(organization, repo)
    okto_singleton.auto_paginate = true
    result = []

    Rails.logger.info "Getting alerts for #{organization}/#{repo}"

    vulnerabilities = okto_singleton.paginate "repos/#{organization}/#{repo}/code-scanning/alerts"
    vulnerabilities.each do |item|
      #binding.pry
      Rails.logger.info "Processing #{item[:number]} - #{item.dig(:rule, :full_description)}" 
      all_instances = okto_singleton.get item[:instances_url]
      puts all_instances.first[:location]
      all_instances_formatted = all_instances.map { |instance| "#{instance[:location][:path]}:#{instance[:location][:start_line]}" }.join(', ')

      result << { id: item[:number], state: item[:state], url: item[:html_url], tool: item.dig(:tool,:name), severity: resolve_tool_severity(item), description: item.dig(:rule, :full_description), all_instances: all_instances_formatted }
    end
    # binding.pry
    result
  end

  def resolve_tool_severity(item)
    case item.dig(:tool, :name).downcase
      when 'codeql'
        item.dig(:rule, :security_severity_level)
      else
        # 'brakeman'  'bearer'
        item.dig(:rule, :severity)
    end
  end

  def get_pr_for_sha(organization, repo, commits)
    Rails.logger.info 'Getting PRs for commits, this takes time'
    okto_singleton.auto_paginate = true

    result = []
    barrier = Async::Barrier.new
    semaphore = Async::Semaphore.new(5, parent: barrier)
    Async do
      commits.each do |item|
        semaphore.async(parent: barrier) do
          sha = item[:sha]
          prs = okto_singleton.commit_pulls("#{organization}/#{repo}", sha)

          if prs.count.zero?
            Rails.logger.warn "No PR for #{sha}"
            result << { commit_sha: sha, data: nil, commit_url: item[:html_url] }
            next
          end
          Rails.logger.info "getting Full PR for #{sha}"
          full_pr = okto_singleton.pull "#{organization}/#{repo}", prs.first.number

          Rails.logger.warn "PR: #{sha} has #{prs.count} PRs processing just first one" if prs.count > 1

          result << { commit_sha: sha, data: full_pr, commit_url: item[:html_url] }
        end
      end
      barrier.wait
    end
    result
  end

  def get_repos_for_select(organization)
    okto_singleton.auto_paginate = true
    repos = okto_singleton.get "orgs/#{organization}/repos"
    while okto_singleton.last_response.rels[:next]
      repos.concat okto_singleton.get(okto_singleton.last_response.rels[:next].href)
    end

    repos.map { |repo| [repo.name, repo.name] }
  end

  def repo_autolinks(organization, repo)
    @repo_autolinks[organization][repo]
  end

  def internal_autolinks_logic(organization, repo)
    begin
        okto_singleton.get "repos/#{organization}/#{repo}/autolinks"
    rescue Octokit::NotFound
        []
    end
  end

  def extract_auto_links(organization, repo, body)
    ticket_section = string_between_markers(body, '# What is the ticket # detailing the issue?',
                                            '# A brief description of the changes')
    return [] if ticket_section.blank?

    result = []
    repo_autolinks(organization, repo).each do |item|
      prefix = item[:key_prefix]
      matches = ticket_section.scan(/#{prefix}\d*/)
      matches.each do |match|
        number = match.gsub(prefix, '') # [/(\d+)[^-]*$/]
        url = item[:url_template]&.gsub('<num>', number)
        result << url
      end
    end
    result
  end

  def format_vulnerabilities_for_download(vulnerabilities)
    Rails.logger.info 'Formatting vulnerabilities for download'
    CSV.generate do |csv|
      csv << ['ID', 'state', 'url', 'tool', 'severity', 'description','instances']
      #      result << { id: item[:number], state: item[:state], url: item[:html_url], tool: item.dig(:tool,:name), severity: resolve_tool_severity(item), description: item.dig(:rule, :full_description)   }
      vulnerabilities.each do |vuln|
        csv << [vuln[:id], vuln[:state], vuln[:url], vuln[:tool], vuln[:severity], vuln[:description], vuln[:all_instances]]
      end
    end
  end   

  def format_pr_set_for_download(organization, repo, prs, other_prs)
    Rails.logger.info 'Formatting PRs for download'
    CSV.generate do |csv|
      csv << ['Relation', 'Commit SHA', 'PR Title', 'PR Size', 'PR Description', 'PR Notes', 'PR URL', 'COMMIT URL',
              'Pivotal Links', 'Redmine Links']
      prs.each do |pr|
        Rails.logger.info "processing #{pr[:commit_sha]}"

        raw_links = extract_ticket_links(pr.dig(:data, :body))
        auto_links = extract_auto_links(organization, repo, pr.dig(:data, :body))

        pivotal = []
        redmine = []
        intelligent_remove_duplicates(raw_links + auto_links).each do |link|
          if link.include?('pivotaltracker.com')
            pivotal << link
          elsif link.include?('redmine')
            redmine << link
          end
        end

        csv << ["Project Change", pr[:commit_sha], pr.dig(:data, :title), evaluate_size_of_pr(pr[:data]),
                extract_description(pr.dig(:data, :body)), extract_notes(pr.dig(:data, :body)), pr.dig(:data, :html_url), pr[:commit_url], pivotal.join(', '), redmine.join(', ')]
      end

      other_prs.each_pair do |repo_name, oprs|
        oprs.each do |opr|
          Rails.logger.info "processing #{opr[:commit_sha]}"

          raw_links = extract_ticket_links(opr.dig(:data, :body))
          auto_links = extract_auto_links(organization, repo_name, opr.dig(:data, :body))

          pivotal = []
          redmine = []
          intelligent_remove_duplicates(raw_links + auto_links).each do |link|
            if link.include?('pivotaltracker.com')
              pivotal << link
            elsif link.include?('redmine')
              redmine << link
            end
          end

          csv << ["Dependency Update", opr[:commit_sha], opr.dig(:data, :title), evaluate_size_of_pr(opr[:data]),
                  extract_description(opr.dig(:data, :body)), extract_notes(opr.dig(:data, :body)), opr.dig(:data, :html_url), opr[:commit_url], pivotal.join(', '), redmine.join(', ')]
        end
      end
    end
  end

  def intelligent_remove_duplicates(links)
    Rails.logger.info "Intelligent remove duplicates from #{links}"
    result = []
    links.uniq.each do |item|
      incl = true
      if item.include?('show')
        # possible dupe on pivotal
        number = item[%r{(\d+)[^/]*$}]
        links.uniq.each do |link|
          Rails.logger.info "Checking #{link} for #{number} aganst #{item}"
          if link.include?(number) && link != item
            # found another link with the same number
            incl = false
          end
        end
      end
      Rails.logger.info "item #{item} returning #{incl}"

      result << item if incl
    end
    result
  end

  def extract_ticket_links(body)
    ticket_section = string_between_markers(body, '# What is the ticket # detailing the issue?',
                                            '# A brief description of the changes')
    return [] if ticket_section.blank?

    result = URI.extract(ticket_section, %w[http https])
    result.each do |item|
      # this is a hack to remove the trailing ) from the link
      item.gsub!(')', '')
    end
    result
  end

  def extract_description(body)
    result = string_between_markers(body, '# A brief description of the changes', '# Feature Flag')
    result = string_between_markers(result, '# A brief description of the changes', '# Environment Variable')
    result&.strip!
    result
  end

  def extract_notes(body)
    return '' if body.blank?
    return '' if body.index('# Additional Context').blank?

    result = body&.split('# Additional Context')&.[](1)
    result = result.remove('Include any additional context that may be relevant to the peer review process.')
    result&.strip!
    result
  end

  def string_between_markers(str, marker1, marker2)
    str&.split(marker1)&.last&.split(marker2)&.first
  end

  def evaluate_size_of_pr(peer_review)
    case peer_review&.dig(:changed_files)
    when 1..3
      'small'
    when 4..10
      'medium'
    when 11..15
      'large'
    when 16..100
      'x-large'
    else
      'unknown'
    end
  end

  def github_rate
    okto_singleton.rate_limit
  end

  class << self
    delegate :github_rate, :get_repos_for_select, :get_sha_between,
             :get_pr_for_sha, :format_pr_set_for_download, :format_vulnerabilities_for_download, :extract_auto_links,
             :get_file_content_at_sha, :get_vulnerabilities, to: :instance
  end
end