# frozen_string_literal: true

require 'csv'
require 'uri'

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
    logger.info "Getting commits for #{organization}/#{repo} between #{start_sha} and #{end_sha}"
    diff = okto_singleton.compare("#{organization}/#{repo}", start_sha, end_sha)
    diff.commits.map { |item| { sha: item.sha, html_url: item.html_url } }
  end

  def get_pr_for_sha(organization, repo, commits)
    logger.info 'Getting PRs for commits, this takes time'
    okto_singleton.auto_paginate = true

    result = []
    commits.each do |item|
      sha = item[:sha]
      prs = okto_singleton.commit_pulls("#{organization}/#{repo}", sha)

      if prs.count.zero?
        logger.warn "No PR for #{sha}"
        result << { commit_sha: sha, data: nil, commit_url: item[:html_url] }
        next
      end
      logger.info "getting Full PR for #{sha}"
      full_pr = okto_singleton.pull "#{organization}/#{repo}", prs.first.number

      logger.warn "PR: #{sha} has #{prs.count} PRs processing just first one" if prs.count > 1

      result << { commit_sha: sha, data: full_pr, commit_url: item[:html_url] }
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

  def internal_autolinks_logic(organization, repo)
    begin
        okto_singleton.get "repos/#{organization}/#{repo}/autolinks"
    rescue Octokit::NotFound
        []
    end
  end

  def repo_autolinks(organization, repo)
    @repo_autolinks ||= internal_autolinks_logic(organization, repo)
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

  def format_pr_for_download(organization, repo, prs)
    logger.info 'Formatting PRs for download'
    CSV.generate do |csv|
      csv << ['Commit SHA', 'PR Title', 'PR Size', 'PR Description', 'PR Notes', 'PR URL', 'COMMIT URL',
              'Pivotal Links', 'Redmine Links']
      prs.each do |pr|
        logger.info "processing #{pr[:commit_sha]}"

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

        csv << [pr[:commit_sha], pr.dig(:data, :title), evaluate_size_of_pr(pr[:data]),
                extract_description(pr.dig(:data, :body)), extract_notes(pr.dig(:data, :body)), pr.dig(:data, :html_url), pr[:commit_url], pivotal.join(', '), redmine.join(', ')]
      end
    end
  end

  def intelligent_remove_duplicates(links)
    logger.info "Intelligent remove duplicates from #{links}"
    result = []
    links.uniq.each do |item|
      incl = true
      if item.include?('show')
        # possible dupe on pivotal
        number = item[%r{(\d+)[^/]*$}]
        links.uniq.each do |link|
          logger.info "Checking #{link} for #{number} aganst #{item}"
          if link.include?(number) && link != item
            # found another link with the same number
            incl = false
          end
        end
      end
      logger.info "item #{item} returning #{incl}"

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
end
