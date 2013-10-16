class HootsuiteController < ApplicationController
  layout "hootsuite"

  def index
    session[:hootsuite] = {
        user_id: nil,
        authenticated: false,
        connected: false,
        theme: params[:theme].blank? ? "blue_steel" : params[:theme],
        userName: "OFunnel",
        query: request.query_string,
        tab: "TARGETS",
        offset: 0,
        target_offset: 0
    }
    if hootsuite_session?
      session[:hootsuite][:authenticated] = true
      session[:hootsuite][:user_id] = params[:uid]
      if check_hootsuite_user_exists? session[:hootsuite][:user_id]
        redirect_to "#{hootsuite_stream_url}?#{session[:hootsuite][:query]}" and return
      end
    end
  end

  def authorize
    session[:return_to] = hootsuite_authorize_callback_url
    redirect_to Settings.linkedin_auth_url, :protocol => 'http' and return
  end

  def authorize_callback
    if set_hootsuite_account(current_user_id,session[:hootsuite][:user_id])
      if check_hootsuite_user_exists? session[:hootsuite][:user_id]
        session[:return_to] = nil
        render "hootsuite/authorize_callback", :layout => false and return
      end
    end
    redirect_to "#{hootsuite_url}?#{session[:hootsuite][:query]}" and return
  end

  def stream
    @offset = 0
    if params[:dataType] == "json"
      unless session[:hootsuite].nil?
        @offset = session[:hootsuite][:offset]
        session[:hootsuite][:offset] = @offset + 25
      end
    else
      session[:hootsuite][:offset] = 25 unless session[:hootsuite].nil?
    end
    @count = 25
    get_all_network_alert_api_endpoint = "#{Settings.api_endpoints.GetAllNetworkAlertsForUserId}/#{current_user_id}/#{@offset}/#{@count}"
    response = Typhoeus.get(get_all_network_alert_api_endpoint)

    @alerts = nil
    if response.success? && !api_contains_error("GetAllNetworkAlertsForUserId", response)
      response = JSON.parse(response.response_body)["GetAllNetworkAlertsForUserIdResult"]
      @remaining = response["alertsRemaining"]
      @alerts = response["allNetworkAlerts"]
      unless params[:dataType] == "json"
        render "hootsuite/stream"
      else
        render :json => response["allNetworkAlerts"], :callback => params[:callback]
      end
    end
  end

  def targets
    @offset = 0
    if params[:dataType] == "json"
      unless session[:hootsuite].nil?
        @offset = session[:hootsuite][:target_offset]
        session[:hootsuite][:target_offset] = @offset + 25
      end
    else
      session[:hootsuite][:target_offset] = 25 unless session[:hootsuite].nil?
    end
    @count = 25
    get_company_network_alert_api_endpoint = URI.escape("#{Settings.api_endpoints.GetNetworkAlerts}/#{current_user_id}/#{@offset}/#{@count}")
    response = Typhoeus.get(get_company_network_alert_api_endpoint)

    @alerts = nil
    if response.success? && !api_contains_error("GetNetworkAlerts", response)
      get_company_network_alert_response = JSON.parse(response.response_body)["GetNetworkAlertsResult"]
      @alerts = get_company_network_alert_response["alert"]
      @total_alerts = get_company_network_alert_response["totalNumberOfAlerts"]
      @total_pages = ((@total_alerts % @count) == 0) ?
          (@total_alerts / @count) :
          ((@total_alerts / @count) + 1)
    end

    @current_page = (@offset < @count) ? 1 : ((@offset / @count) + 1)
    @page_remaining = @total_pages.nil? ?
        0 :
        (@total_pages > 0 and @total_pages > @current_page) ?
            (@total_pages - @current_page) : 0

    unless params[:dataType] == "json"
      render "hootsuite/targets"
    else
      render :json => JSON.parse(response.response_body)["GetNetworkAlertsResult"], :callback => params[:callback]
    end
  end

  def disconnect
    delete_hootsuite_user_api_endpoint = "#{Settings.api_endpoints.DeleteHootSuiteAccount}/#{current_user_id}"
    response = Typhoeus.get(delete_hootsuite_user_api_endpoint)
    query = session[:hootsuite][:query] unless session[:hootsuite].nil?

    if response.success? && !api_contains_error("DeleteHootSuiteAccount", response)
      response = JSON.parse(response.response_body)["DeleteHootSuiteAccountResult"]
      if response["isHootSuiteIdDeleted"] == true
        reset_session
      end
    end
    redirect_to "#{hootsuite_path}#{('?' + query) unless query.nil?}" and return
  end

  protected

  def hootsuite_session?
    return Digest::SHA1.hexdigest("#{params[:i]}#{params[:ts]}0f8684b4973c8dccd771273a2e9ea012b30a7729de4e55be6dd5a5e17399dfe0c9475c7dabcb8fa693104e821fedf5ac076523c422759ed9d1b29828a9cb4491") == params[:token]
  end

  def check_hootsuite_user_exists?(h_user_id)
    check_hootsuite_user_api_endpoint = "#{Settings.api_endpoints.CheckHootSuiteUserExist}/#{h_user_id}"
    response = Typhoeus.get(check_hootsuite_user_api_endpoint)

    status = false
    if response.success? && !api_contains_error("CheckHootSuiteUserExist", response)
      response = JSON.parse(response.response_body)["CheckHootSuiteUserExistResult"]
      if response["isHootSuiteUserExist"] == true
        session[:hootsuite][:tab] = "ALERTS"
        session[:hootsuite][:connected] = true
        session[:hootsuite][:userName] = response["ofunnelUserName"]
        set_current_user_id response["ofunnelUserId"]
        status = true
      end
    end
    return status
  end

  def set_hootsuite_account(user_id,h_user_id)
    api_endpoint = "#{Settings.api_endpoints.SetHootSuiteAccount}"
    response = Typhoeus.post(
        api_endpoint,
        body: {
            userId: user_id,
            hootSuiteId: h_user_id
        })

    status = false
    if response.success? && !api_contains_error("SetHootSuiteAccount", response)
      api_response = JSON.parse(response.response_body)["SetHootSuiteAccountResult"]
      if api_response["isHootSuiteIdSet"] == true
        status = true
      end
    end
    return status
  end
end