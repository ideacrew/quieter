# Get dependent gems and tell me the versions of them in use at given times
class GemVersionService
  include Singleton

  def extract_gem_differences(org, project, sha1, sha2)
    earlier = extract_gem_list_for_sha(org, project, sha1)
    later = extract_gem_list_for_sha(org, project, sha2)
    all_gem_names = (later.keys + earlier.keys).uniq
    puts all_gem_names.inspect
    differences = {}
    all_gem_names.each do |gn|
      if earlier[gn] && later[gn]
        earlier_sha = extract_github_sha_from_spec(earlier[gn])
        later_sha = extract_github_sha_from_spec(later[gn])
        if earlier_sha != later_sha
          differences[gn] = {
            earlier: earlier_sha,
            later: later_sha
          }
        end
      elsif later[gn]
        later_sha = extract_github_sha_from_spec(later[gn])
        differences[gn] = {
          earlier: nil,
          later: later_sha
        }
      end
    end
    differences
  end

  def extract_github_sha_from_spec(spec)
    spec.source.revision
  end

  def extract_gem_list_for_sha(org, project, sha)
    gems = dependent_gems_for(org, project)
    lockfile_data = GithubService.get_file_content_at_sha(org, project, sha, "Gemfile.lock")
    lockfile_inventory = ::Bundler::LockfileParser.new(lockfile_data)
    gem_names = gems.map(&:name)
    matching_specs = {}
    lockfile_inventory.specs.each do |spec|
      if gem_names.include?(spec.name)
        matching_specs[spec.name] = spec
      end
    end
    matching_specs
  end

  def dependent_gems_for(org, project)
    project = Project.where(:org => org, :name => project).first
    return [] unless project
    project.project_gems
  end

  class << self
    delegate :extract_gem_differences, to: :instance
  end
end