class HootsuiteController < ApplicationController
  layout "hootsuite"

  def index
    create_default_hootsuite_session
    if hootsuite_session?
      cookies.permanent.signed[:authenticated] = {:value => true, :domain => :all}
      cookies.permanent.signed[:h_user_id] = {:value => params[:uid], :domain => :all}
      if check_hootsuite_user_exists? cookies.signed[:h_user_id]
        if cookies.signed[:tab] ==  "ALERTS"
          redirect_to "#{hootsuite_stream_url}?#{cookies.signed[:query]}" and return
        else
          redirect_to "#{hootsuite_targets_url}?#{cookies.signed[:query]}" and return
        end
      end
    end
  end

  def authorize
    cookies.permanent.signed[:return_to] = {:value => hootsuite_authorize_callback_url, :domain => :all}
    redirect_to "#{Settings.linkedin_auth_url}?back_url=#{hootsuite_authorize_callback_url}", :protocol => 'http' and return
  end

  def authorize_callback
    logger.fatal cookies.signed[:user_id]
    logger.fatal cookies.signed[:h_user_id]
    logger.fatal cookies.signed[:query]
    user_id = cookies.signed[:user_id]
    h_user_id = cookies.signed[:h_user_id]
    @query = cookies.signed[:query]
    @authenticated = false
    unless h_user_id.blank?
      if set_hootsuite_account(user_id,h_user_id)
        check_hootsuite_user_exists? h_user_id
        cookies.permanent.signed[:return_to] = {:value => nil, :domain => :all}
        @authenticated = true
      end
    end
    render "hootsuite/authorize_callback", :layout => false and return
  end

  def stream
    @offset = 0
    cookies.permanent.signed[:tab] = {:value => "ALERTS", :domain => :all}
    if params[:dataType] == "json"
      @offset = cookies.signed[:offset]
      cookies.permanent.signed[:offset] = {:value => @offset + 25, :domain => :all}
    else
      cookies.permanent.signed[:offset] = {:value => 25, :domain => :all}
    end
    @count = 25
    get_all_network_alert_api_endpoint = "#{Settings.api_endpoints.GetAllNetworkAlertsForUserId}/#{current_user_id_from_cookies}/#{@offset}/#{@count}"
    response = Typhoeus.get(get_all_network_alert_api_endpoint)

    @alerts = nil
    @is_subscription_expired = false
    @subscription_message = ""
    if response.success? && !api_contains_error("GetAllNetworkAlertsForUserId", response)
      response = JSON.parse(response.response_body)["GetAllNetworkAlertsForUserIdResult"]
      @remaining = response["alertsRemaining"]
      @alerts = response["allNetworkAlerts"]
      @is_subscription_expired = response["isExpired"]
      @subscription_message = response["subscriptionMessage"]
      unless params[:dataType] == "json"
        render "hootsuite/stream"
      else
        render :json => response["allNetworkAlerts"], :callback => params[:callback]
      end
    end
  end

  def targets
    @offset = 0
    cookies.permanent.signed[:tab] = {:value => "TARGETS", :domain => :all}
    if params[:dataType] == "json"
      @offset = cookies.signed[:target_offset]
      cookies.permanent.signed[:target_offset] = {:value => @offset + 25, :domain => :all}
    else
      cookies.permanent.signed[:target_offset] = {:value => 25, :domain => :all}
    end
    @count = 25
    get_company_network_alert_api_endpoint = URI.escape("#{Settings.api_endpoints.GetNetworkAlerts}/#{current_user_id_from_cookies}/#{@offset}/#{@count}")
    response = Typhoeus.get(get_company_network_alert_api_endpoint)

    @alerts = nil
    if response.success? && !api_contains_error("GetNetworkAlerts", response)
      get_company_network_alert_response = JSON.parse(response.response_body)["GetNetworkAlertsResult"]
      @alerts = get_company_network_alert_response["targetAccount"]
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

  def get_linkedin_profile
    api_endpoint = "#{Settings.api_endpoints.GetPersonProfile}/#{cookies.signed[:user_id]}/#{params[:linkedin_id]}"
    response = Typhoeus.get(api_endpoint)
    content = { "error" => nil }

    if response.success? && !api_contains_error("GetPersonProfile", response)
      response = JSON.parse(response.response_body)["GetPersonProfileResult"]
      content = response["personProfile"]
    end
    render :json => content.to_json, :callback => params[:callback]
  end

  def disconnect
    delete_hootsuite_user_api_endpoint = "#{Settings.api_endpoints.DeleteHootSuiteAccount}/#{current_user_id_from_cookies}"
    response = Typhoeus.get(delete_hootsuite_user_api_endpoint)
    query = cookies.signed[:query]

    if response.success? && !api_contains_error("DeleteHootSuiteAccount", response)
      response = JSON.parse(response.response_body)["DeleteHootSuiteAccountResult"]
      if response["isHootSuiteIdDeleted"] == true
        create_default_hootsuite_session
      end
    end
    redirect_to "#{hootsuite_path}?#{query}" and return
  end

  def add_relationships
    unless params[:alertJson].blank?
      target_accounts = JSON.parse(params[:alertJson])
      alert_json = {
          :targetAccount => []
      }

      alert_array = []
      target_accounts.each do |target|
        alert_array.push(
            {
                :filterType => target["type"],
                :targetName => target["name"],
                :targetAccountId => target["alertId"],
                :secondLevelFilterDetails => nil
            }
        )
      end

      alert_json[:targetAccount] = alert_array

      persist_company_network_alert_api_endpoint = "#{Settings.api_endpoints.PersistNetworkAlerts}"
      persist_company_network_alert_response = nil

      hydra = Typhoeus::Hydra.hydra
      persist_company_network_alert_request = Typhoeus::Request.new(
          persist_company_network_alert_api_endpoint,
          method: :post,
          body: {
              userId: current_user_id,
              alertJson: alert_json.to_json
          })

      hydra.queue persist_company_network_alert_request

      persist_company_network_alert_request.on_complete do |response|
        persist_company_network_alert_response = response
      end

      hydra.run
      status = true
      if persist_company_network_alert_response.success? && !api_contains_error("PersistNetworkAlerts", persist_company_network_alert_response)
        session[:track_alert_event] = true
        api_response = JSON.parse(persist_company_network_alert_response.response_body)["PersistNetworkAlertsResult"]
        status = api_response["isNetworkAlertPersisted"] == true ? nil : true
      end
      render :json => {"error" => status} and return
    else
      render :json => {"error" => true} and return
    end
  end

  def remove_relationship
    type = params[:type]
    name = params[:name]
    alert_id = params[:alertId]

    remove_company_network_alert_api_endpoint = "#{Settings.api_endpoints.RemoveNetworkAlert}"
    response = Typhoeus.post(
        remove_company_network_alert_api_endpoint,
        body: {
            userId: current_user_id,
            alertId: alert_id
        })

    if response.success? && !api_contains_error("RemoveNetworkAlert", response)
      api_response = JSON.parse(response.response_body)["RemoveNetworkAlertResult"]
    else
      api_response = {"error" => nil}
    end
    render :json => api_response.to_json, :callback => params[:callback]
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
        cookies.permanent.signed[:connected] = {:value => true, :domain => :all}
        cookies.permanent.signed[:userName] = {:value => response["ofunnelUserName"], :domain => :all}
        cookies.permanent.signed[:user_id] = {:value => response["ofunnelUserId"], :domain => :all}
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
