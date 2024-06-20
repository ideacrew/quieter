class AhaService

  AHA_BASE_URL = "https://ideacrew.aha.io"

  include Singleton

  def initialize
    @connection_singleton = Faraday.new(url: AHA_BASE_URL) do |faraday|
      faraday.request :authorization, :Bearer, ENV['AHA_TOKEN']
      faraday.request :json
    end
  end

  def get_initiative(initiative_id)
    response = @connection_singleton.get "/api/v1/initiatives/#{initiative_id}"
    JSON.parse(response.body)["initiative"]
  end

  def get_feature(feature_id)
    response = @connection_singleton.get "/api/v1/features/#{feature_id}"
    JSON.parse(response.body)["feature"]
  end

  def get_requirement(requirement_id)
    response = @connection_singleton.get "/api/v1/requirements/#{requirement_id}"
    JSON.parse(response.body)["requirement"]
  end

  class << self
    delegate :get_initiative, :get_feature, :get_requirement, to: :instance
  end
end