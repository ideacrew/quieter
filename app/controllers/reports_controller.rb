class ReportsController < ApplicationController
  def home
  end

  def range
    @organizations = ["ideacrew", "dchbx"]
    @repos_array = helpers.get_repos_for_select(@organizations.last)
  end

  def execute_range
    commits=helpers.get_sha_between(params[:organization],params[:repo],params[:start_sha], params[:end_sha])
    prs = helpers.get_pr_for_sha(params[:organization],params[:repo],commits)
    csv_string = helpers.format_pr_for_download(params[:organization],params[:repo],prs)
    send_data csv_string, :filename => 'range_report.csv', :type => 'text/csv; charset=utf-8; header=present'
  end

  def mttm
  end
end
