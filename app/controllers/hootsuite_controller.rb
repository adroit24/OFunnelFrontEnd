class HootsuiteController < ApplicationController
  layout "hootsuite"

  def session_init
    session[:hootsuite] = {
        :user_id => nil,
        :authenticated => false,
        :connected => false,
        :theme => params[:theme].blank? ? "blue_steel" : params[:theme],
        :userName => "",
        :query => request.query_string,
        :tab => "TARGETS"
    }
    if hootsuite_session?
      session[:hootsuite][:authenticated] = true
      session[:hootsuite][:user_id] = params[:uid]
    end

    unless check_hootsuite_user_exists? session[:hootsuite][:user_id]
      redirect_to hootsuite_path
    else
      redirect_to "#{hootsuite_stream_url}?#{session[:hootsuite][:query]}"
    end
  end

  def index
    #session_id = request.session_options[:id]
    #iv =  OFunnel::Application.config.iv
    #key = OFunnel::Application.config.key
    #
    #cipher = OpenSSL::Cipher::AES.new(128, :CBC)
    #cipher.encrypt
    #cipher.key = key
    #cipher.iv = iv
    #
    #encrypted = cipher.update(session_id)
    #encrypted << cipher.final
    #
    #@e_session = Base64.encode64(encrypted).encode('utf-8')
  end

  def authorize
    #unless params[:token].blank?
    #token = params[:token]
    #iv =  OFunnel::Application.config.iv
    #key = OFunnel::Application.config.key
    #
    #decipher = OpenSSL::Cipher::AES.new(128, :CBC)
    #decipher.decrypt
    #decipher.key = key
    #decipher.iv = iv
    #
    #d_token = Base64.decode64(token).encode('ascii-8bit')
    #session_id = decipher.update(d_token)
    #session_id << decipher.final

    #session[:ref_session] = session_id
    session[:return_to] = hootsuite_authorize_callback_url
    redirect_to Settings.linkedin_auth_url, :protocol => 'http' and return
    #end
  end

  def authorize_callback

    set_hootsuite_account(current_user_id,session[:hootsuite][:user_id])

    #unless session[:ref_session] == request.session_options[:id]
    #  old_s = Sessions.find_by_session_id session[:ref_session]
    #  new_s = Sessions.find_by_session_id request.session_options[:id]
    #  old_s.update_attributes!({
    #                               :data => new_s.data
    #                           })
    #end
    #session[:ref_session] = nil
    session[:return_to] = nil
  end

  def stream
    @offset = 0
    if params[:dataType] == "json"
      unless session[:hootsuite].nil? or session[:hootsuite][:offset].nil?
        @offset = session[:hootsuite][:offset]
        session[:hootsuite][:offset] = @offset + 25
      else
        session[:hootsuite][:offset] = 25
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

    if response.success? && !api_contains_error("SetHootSuiteAccount", response)
      api_response = JSON.parse(response.response_body)["SetHootSuiteAccountResult"]
    end
  end
end
