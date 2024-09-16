class ReportsController < ApplicationController
  def home
  end

  def repos
    @repos_array = helpers.get_repos_for_select(params[:organization])
    render json: {
      repos: @repos_array.flatten.uniq,
      github_rate: GithubService.github_rate
    }
  end

  def range
    @organizations = ["ideacrew", "dchbx"]
    render inertia: "reports/RangeComponent", props: { 
      orgs: @organizations,
      submit_url: execute_range_report_path,
      repos_url: repos_reports_path,
      csrf_token: form_authenticity_token,
      github_rate: GithubService.github_rate
    }
  end

  def security
    @organizations = ["ideacrew", "dchbx", "health-connector"]

    render inertia: "reports/SecurityComponent", props: { 
      orgs: @organizations,
      submit_url: execute_security_export_path,
      repos_url: repos_reports_path,
      csrf_token: form_authenticity_token,
      github_rate: GithubService.github_rate
    }
  end

  def execute_security_export
    csv_string = CsvService.security_csv_for_project(params[:organization],params[:repo])
    filename = "#{params[:organization]}_#{params[:repo]}_security.csv"
    send_data csv_string, :filename => filename, :type => 'text/csv; charset=utf-8; header=present'
  end

  def execute_range
    csv_string = CsvService.csv_for_project(params[:organization],params[:repo],params[:start_sha], params[:end_sha])
    filename = "#{params[:organization]}_#{params[:repo]}_#{params[:start_sha]}_#{params[:end_sha]}.csv"
    send_data csv_string, :filename => filename, :type => 'text/csv; charset=utf-8; header=present'
  end

  def mttm
  end
end
