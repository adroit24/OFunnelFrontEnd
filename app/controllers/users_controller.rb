class UsersController < ApplicationController

  before_filter :check_current_user, :except => [:unsubscribe]
  before_filter :set_tab

  def show
    @id = params[:id]
    api_endpoint = "#{Settings.api_endpoints.GetUserProfileFromUserId}/#{@id}"
    response = Typhoeus.get(api_endpoint)
    @profile = {}
    if response.success? && !api_contains_error("GetUserProfileFromUserId", response)
      @profile = JSON.parse(response.response_body)["GetUserProfileFromUserIdResult"]
    else
      @profile["error"] = nil
      log_errors(response.return_message)
    end
  end

  def logout
    api_endpoint = "#{Settings.api_endpoints.Logout}"
    response = Typhoeus.post(api_endpoint, body: {
        userId: current_user_id
    })

    if response.success? && !api_contains_error("Logout", response)
      reset_session
    end

    redirect_to Settings.logout_redirect
  end

  def connections_strength
    @user_name = params[:user_name].capitalize
    @offset = params[:offset].nil? ? 0 : params[:offset]
    total = 100
    api_endpoint = "#{Settings.api_endpoints.GetConnectionsReport}/#{current_user_id}/#{@offset}/#{total}"
    response = Typhoeus.get(api_endpoint)
    if response.success? && !api_contains_error("GetConnectionsReport", response)
      response = JSON.parse(response.response_body)["GetConnectionsReportResult"]
      @connections = response["connectionsReport"]
      @prev_flag = (@offset.to_i < 100) ? false : true
      @next_flag = (response["remainingConnectionsReport"].to_i > 0) ? true : false
      @offset = @offset.to_i + 100
    else
      @connections = nil
    end
  end

  def update_connections_strength
    connections_strength = JSON.parse(params[:connectionsStrengthJson])
    user_name = params[:user_name]
    offset = params[:offset]
    updated_strength_json = {
        :connectionStrength => []
    }

    connections_strength.each_with_index do |connection,index|
      updated_strength_json[:connectionStrength].push(
          {
              :accountId => connection[0],
              :updatedStrength => connection[1]
          }
      )
    end

    api_endpoint = "#{Settings.api_endpoints.UpdateConnectionsStrength}"
    response = Typhoeus.post(api_endpoint, body: {
        userId: current_user_id,
        connectionsUpdatedStrengthJson: updated_strength_json.to_json
    })

    #if response.success? && !api_contains_error("UpdateConnectionsStrength", response)
    #  response = JSON.parse(response.response_body)["UpdateConnectionsStrengthResult"]
    #else
    #
    #end
    redirect_to connections_strength_path({:user_name => user_name,:offset => offset})
  end

  def notifications
    alert_count = 5
    get_user_profile_api_endpoint = "#{Settings.api_endpoints.GetUserProfileFromUserId}/#{current_user_id}"
    get_network_alert_api_endpoint = "#{Settings.api_endpoints.GetNetworkAlertsForUserId}/#{current_user_id}/#{alert_count}"
    get_alerts_recipient_api_endpoint = "#{Settings.api_endpoints.GetRecipientsEmailForNetworkAlerts}/#{current_user_id}"
    get_email_frequency_api_endpoint = "#{Settings.api_endpoints.GetEmailFrequencyPreferences}/#{current_user_id}/ALERT"
    get_subscription_info_api_endpoint = "#{Settings.api_endpoints.GetSubscriptionDetails}/#{current_user_id}"
    get_user_profile_api_response = nil
    get_network_alert_api_response = nil
    get_alerts_recipient_response = nil
    get_email_frequency_response = nil
    get_subscription_info_response = nil

    hydra = Typhoeus::Hydra.hydra
    get_user_profile_api_request = Typhoeus::Request.new(get_user_profile_api_endpoint)
    get_network_alert_api_request = Typhoeus::Request.new(get_network_alert_api_endpoint)
    get_alerts_recipient_request = Typhoeus::Request.new(get_alerts_recipient_api_endpoint)
    get_email_frequency_request = Typhoeus::Request.new(get_email_frequency_api_endpoint)
    get_subscription_info_request = Typhoeus::Request.new(get_subscription_info_api_endpoint)

    hydra.queue get_user_profile_api_request
    hydra.queue get_network_alert_api_request
    hydra.queue get_alerts_recipient_request
    hydra.queue get_email_frequency_request
    hydra.queue get_subscription_info_request
    get_user_profile_api_request.on_complete do |response|
      get_user_profile_api_response = response
    end
    get_network_alert_api_request.on_complete do |response|
      get_network_alert_api_response = response
    end
    get_alerts_recipient_request.on_complete do |response|
      get_alerts_recipient_response = response
    end
    get_email_frequency_request.on_complete do |response|
      get_email_frequency_response = response
    end
    get_subscription_info_request.on_complete do |response|
      get_subscription_info_response = response
    end
    hydra.run

    @profile = {}
    if get_user_profile_api_response.success? && !api_contains_error("GetUserProfileFromUserId", get_user_profile_api_response)
      @profile = JSON.parse(get_user_profile_api_response.response_body)["GetUserProfileFromUserIdResult"]
    else
      @profile["error"] = nil
      log_errors(get_user_profile_api_response.return_message)
    end

    @alerts_for_company = nil
    @alerts_for_person = nil
    @alerts_for_position = nil
    @alerts_for_role = nil
    if get_network_alert_api_response.success? && !api_contains_error("GetNetworkAlertsForUserId", get_network_alert_api_response)
      result = JSON.parse(get_network_alert_api_response.response_body)["GetNetworkAlertsForUserIdResult"]
      if result["error"] == nil
        unless result["networkAlertForCompany"].nil?
          @alerts_for_company = result["networkAlertForCompany"]["alertsForCompany"]
        end
        unless result["networkAlertForPersonName"].nil?
          @alerts_for_person = result["networkAlertForPersonName"]["alertsForPersonName"]
        end
        unless result["networkAlertForPosition"].nil?
          @alerts_for_position = result["networkAlertForPosition"]["alertsForPosition"]
        end
        unless result["networkAlertForRole"].nil?
          @alerts_for_role = result["networkAlertForRole"]["alertsForRole"]
        end
      end
    end

    @emails = nil
    if get_alerts_recipient_response.success? && !api_contains_error("GetRecipientsEmailForNetworkAlerts", get_alerts_recipient_response)
      api_response = JSON.parse(get_alerts_recipient_response.response_body)["GetRecipientsEmailForNetworkAlertsResult"]
      @emails = api_response["recipientEmailDetails"] if api_response["error"] == nil
    end

    @frequency = "DAILY"
    if get_email_frequency_response.success? && !api_contains_error("GetEmailFrequencyPreferences", get_email_frequency_response)
      api_response = JSON.parse(get_email_frequency_response.response_body)["GetEmailFrequencyPreferencesResult"]
      @frequency = api_response["emailFrequency"]
    end

    @subscription = nil
    if get_subscription_info_response.success? && !api_contains_error("GetSubscriptionDetails", get_subscription_info_response)
      api_response = JSON.parse(get_subscription_info_response.response_body)["GetSubscriptionDetailsResult"]
      @subscription = api_response
    end

    if mobile_device
      render "responsive_alerts", :layout => "responsive_relationships"
    elsif params[:view] == "hootsuite"
      render "responsive_alerts", :layout => "hootsuite"
    elsif params[:view] == "desktop"
      render "alerts", :layout => "relationships"
    else
      render "alerts", :layout => "relationships"
    end
  end

  def notification_frequency
    api_endpoint = "#{Settings.api_endpoints.SetEmailFrequencyPreferences}"
    response = Typhoeus.post(api_endpoint, body: {
        userId: current_user_id,
        emailType: "ALERT",
        emailFrequency: params[:frequency]
    })

    status = false
    if response.success? && !api_contains_error("SetEmailFrequencyPreferences", response)
      response = JSON.parse(response.response_body)["SetEmailFrequencyPreferencesResult"]
      status = !response["isEmailFrequencyPreferencesSet"]
    end

    render :json => {"ERROR" => status}.to_json
  end

  def unsubscribe
    if session[:linkedin_id].nil?
       redirect_to "#{Settings.logout_redirect}?action=unsubscribe&id=#{params[:id]}"
    else
       redirect_to notifications_path
    end
  end

  def add_to_salesforce
    first_name = params[:firstName]
    last_name = params[:lastName]
    title = params[:title]
    company = params[:company]

    api_endpoint = "#{Settings.api_endpoints.AddSalesForceConnectionFromNetworkAlerts}"
    response = Typhoeus.post(api_endpoint, body: {
        userId: current_user_id,
        firstName: first_name,
        lastName: last_name,
        title: title,
        company: company
    })

    status = "ERROR"
    if response.success? && !api_contains_error("AddSalesForceConnectionFromNetworkAlerts", response)
      response = JSON.parse(response.response_body)["AddSalesForceConnectionFromNetworkAlertsResult"]
      status = "SUCCESS"
      render :text => status and return false
    else
      response = JSON.parse(response.response_body)["AddSalesForceConnectionFromNetworkAlertsResult"]
      code = nil
      code = response["error"]["errorCode"].to_i unless response["error"].nil?
      if code == 401 or code == 1003
        session[:salesforce_token] = nil
        session[:return_to] = alerts_url
        render :text => Settings.salesforce_auth_url and return
      else
        render :text => status and return false
      end
    end
  end

  def all_alerts
    account_id = params[:id]
    @type = params[:type]
    get_all_network_alert_api_endpoint = "#{Settings.api_endpoints.GetAllNetworkAlertsForTargetAccount}/#{current_user_id}/#{account_id}"
    get_all_network_alert_api_response = nil

    hydra = Typhoeus::Hydra.hydra
    get_all_network_alert_api_request = Typhoeus::Request.new(get_all_network_alert_api_endpoint)
    hydra.queue get_all_network_alert_api_request
    get_all_network_alert_api_request.on_complete do |response|
      get_all_network_alert_api_response = response
    end
    hydra.run

    @alerts = nil
    if get_all_network_alert_api_response.success? && !api_contains_error("GetAllNetworkAlertsForTargetAccount", get_all_network_alert_api_response)
      result = JSON.parse(get_all_network_alert_api_response.response_body)["GetAllNetworkAlertsForTargetAccountResult"]
      if result["error"] == nil
        @alerts = result["networkAlertsForTargetAccount"]
      end
    end
    if (mobile_device and params[:view] != "desktop")
      render "responsive_all_alerts", :layout => "responsive_relationships"
    else
      render "all_alerts", :layout => "relationships"
    end
  end

  protected

  def set_tab
    session[:selected_tab] = "users"
    session[:active_tab] = ""
  end
end
