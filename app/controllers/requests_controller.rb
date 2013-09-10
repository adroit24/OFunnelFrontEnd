class RequestsController < ApplicationController

  before_filter :check_current_user, :set_tab, :except => [:show]

  def index
    case params[:format]
      when "sent"
        get_all_sent_requests
      when "received"
        get_all_received_requests
      else
        get_all_received_requests
    end
  end

  def new_open_request
    unless params[:title].nil? or params[:title].blank?
      query = params[:title]
      query_array = query.split(' at ')
      company = query_array[1].nil? ? query : query_array[1].strip
      linkedin_id = params[:linkedin_id]
      api_endpoint = "#{Settings.api_endpoints.AddRequest}"
      visibility_tags_array = params[:visibility_tags].split(',')
      visibilityTags = [ ]
      visibility_tags_array.each do |tag|
        visibilityTags << {
            "tagId" => tag
        }
      end
      response = Typhoeus.post(api_endpoint, body: {
          companySearched: company,
          querySearched: query,
          content: params[:message],
          fromUserId: current_user_id,
          forUserId: nil,
          toUserId: nil,
          forUserlinkedInId: linkedin_id,
          status: "PENDING",
          visibilityTags: {"visibilityTags" => visibilityTags}.to_json
      })
    end
    redirect_to requests_path
  end

  def show
    session[:token] = params[:id]
    redirect_to authorize_with_likedin_path
  end

  def edit
    request_id = params[:id]
    status = params[:format]
    api_endpoint = "#{Settings.api_endpoints.UpdateRequestStatus}"
    response = Typhoeus.post(api_endpoint, body: {
        requestId: request_id,
        status: status,
        updateScoreForUserId: current_user_id,
        forUserLinkedInId: ""
    })
    if response.success? && !api_contains_error("UpdateRequestStatus", response)
      response = JSON.parse(response.response_body)["UpdateRequestStatusResult"]
      if response["rowsEffected"].to_i == 1
        set_current_user_score(response["updatedScore"])
      end
    end
    if request.xhr?
      render :partial => "requests/ignore"
    else
      redirect_to requests_path("received")
    end
  end

  def accept
    request_id = params[:id]
    for_user_account_id = params[:forUserAccountId]
    type = params[:type]
    name = params[:name]
    api_endpoint = "#{Settings.api_endpoints.AcceptRequest}"
    response = Typhoeus.post(api_endpoint, body: {
        requestId: request_id,
        updateScoreForUserId: current_user_id,
        forUserAccountId: for_user_account_id,
        accountType: type,
        name: name
    })
    api_response = nil
    if response.success? && !api_contains_error("AcceptRequest", response)
      response = JSON.parse(response.response_body)["AcceptRequestResult"]
      if response["rowsEffected"].to_i == 1
        set_current_user_score(response["updatedScore"])
      end
      api_response = response
    else
      api_response = {"error" => true}
    end
    render :json => api_response.to_json
    #redirect_to requests_path("received")
  end

  def ignore
    request_id = params[:id]
    api_endpoint = "#{Settings.api_endpoints.IgnoreRequest}"
    response = Typhoeus.post(api_endpoint, body: {
        requestId: request_id,
        userId: current_user_id
    })
    api_response = nil
    if response.success? && !api_contains_error("IgnoreRequest", response)
      response = JSON.parse(response.response_body)["IgnoreRequestResult"]
      #if response["requestStatus"] == "IGNORED"
      #end
    end
    render :partial => "requests/ignore"
  end

  def update_request_info
    request_id = params[:request_id]
    query = params[:title]
    query_array = query.split(' at ')
    company = query_array[1].nil? ? query : query_array[1].strip
    message = params[:message]
    linkedin_id = params[:linkedin_id]
    visibility_tags_array = params[:visibility_tags].split(',')
    visibilityTags = [ ]
    visibility_tags_array.each do |tag|
      visibilityTags << {
          "tagId" => tag
      }
    end
    api_endpoint = "#{Settings.api_endpoints.UpdateRequest}"
    response = Typhoeus.post(api_endpoint, body: {
        requestId: request_id,
        companySearched: company,
        querySearched: query,
        forUserlinkedInId: linkedin_id,
        content: message,
        visibilityTags: {"visibilityTags" => visibilityTags}.to_json
    })
    redirect_to requests_path("sent")
  end

  def more_info
    request_id = params[:id]
    api_endpoint = "#{Settings.api_endpoints.RequestForMoreInformation}"
    response = Typhoeus.post(api_endpoint, body: {
        requestId: request_id,
        userId: current_user_id
    })
    if response.success? && !api_contains_error("RequestForMoreInformation", response)
      response = JSON.parse(response.response_body)["RequestForMoreInformationResult"]
    end
    render :partial => "requests/more_info"
  end

  def delete
  end

  protected

  def set_tab
    session[:selected_tab] = "requests"
  end

  def get_all_sent_requests
    session[:active_tab] = "sent"
    get_all_request_api_endpoint = "#{Settings.api_endpoints.GetAllRequestsMade}/#{current_user_id}"
    get_all_request_response = nil

    hydra = Typhoeus::Hydra.hydra
    get_all_request = Typhoeus::Request.new(get_all_request_api_endpoint)
    hydra.queue get_all_request
    get_all_request.on_complete do |response|
      get_all_request_response = response
    end

    hydra.run

    if get_all_request_response.success? && !api_contains_error("GetRequestsMade", get_all_request_response)
      @requests = JSON.parse(get_all_request_response.response_body)["GetRequestsMadeResult"]["requestDetails"]
    else
      @requests = nil
    end
  end

  def get_all_received_requests
    session[:active_tab] = "received"

    get_requests_api_endpoint = "#{Settings.api_endpoints.GetAllRequestsGot}/#{current_user_id}"
    get_requests_response = nil

    hydra = Typhoeus::Hydra.hydra
    get_requests_request = Typhoeus::Request.new(get_requests_api_endpoint)
    hydra.queue get_requests_request
    get_requests_request.on_complete do |response|
      get_requests_response = response
    end
    hydra.run

    if get_requests_response.success? && !api_contains_error("GetRequestsGot", get_requests_response)
      @requests = JSON.parse(get_requests_response.response_body)["GetRequestsGotResult"]["requestDetails"]
    else
      @requests = nil
    end
  end
end
