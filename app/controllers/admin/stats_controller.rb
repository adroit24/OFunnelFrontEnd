class Admin::StatsController < ApplicationController
  def index
  end

  def show
    id = params[:user_id]
    @network = nil
    @accounts = nil
    unless id.blank?
      get_expansion_details_api_endpoint = "#{Settings.api_endpoints.GetNetwrokExpandDetailsForUserId}/#{id}"
      get_similar_companies_api_endpoint = "#{Settings.api_endpoints.GetSimilarCompanies}/Microsoft/0/5"

      get_expansion_details_api_response = nil
      get_similar_companies_api_response = nil

      hydra = Typhoeus::Hydra.hydra
      get_expansion_details_api_request = Typhoeus::Request.new(get_expansion_details_api_endpoint)
      get_similar_companies_api_request = Typhoeus::Request.new(get_similar_companies_api_endpoint)

      hydra.queue get_expansion_details_api_request
      hydra.queue get_similar_companies_api_request

      get_expansion_details_api_request.on_complete do |response|
        get_expansion_details_api_response = response
      end
      get_similar_companies_api_request.on_complete do |response|
        get_similar_companies_api_response = response
      end
      hydra.run

      if get_expansion_details_api_response.success? && !api_contains_error("GetNetwrokExpandDetailsForUserId", get_expansion_details_api_response)
        response = JSON.parse(get_expansion_details_api_response.response_body)["GetNetwrokExpandDetailsForUserIdResult"]
        @network = response["networkExpandDetails"] if response["error"].blank?
      end
      if get_similar_companies_api_response.success? && !api_contains_error("GetSimilarCompanies", get_similar_companies_api_response)
        response = JSON.parse(get_similar_companies_api_response.response_body)["GetSimilarCompaniesResult"]
        @accounts = response["companyDetails"] if response["error"].blank?
      end
    end
  end
end
