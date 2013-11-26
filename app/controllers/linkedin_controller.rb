class LinkedinController < ApplicationController
  before_filter :check_current_user, :except => [:index, :authorize_with_likedin, :linkedin_authorization_callback]
  before_filter :set_tab

  require 'mime/types' #mime-types gem
  require 'roo'

  def index
    unless current_user.nil?
      redirect_to alerts_path and return
    else
      redirect_to Settings.logout_redirect and return
    end
  end

  def authorize_with_likedin
    session[:linkedin_token] = nil
    session[:google_token] = nil
    session[:facebook_token] = nil
    session[:salesforce_token] = nil
    if params[:id] == "no_back"
      session[:return_to] = nil
    end

    ofunnel_callback = Settings.linkedin.REDIRECT_URI
    #Redirect your user in order to authenticate
    redirect_url = linkedin_client.auth_code.authorize_url(
        :scope => 'r_fullprofile r_emailaddress rw_nus r_network',
        :state => Settings.linkedin.STATE,
        :redirect_uri => ofunnel_callback
    )
    logger.fatal "Redirect to linkedin for first time: #{ofunnel_callback}"
    redirect_to redirect_url
  end

  # This method will handle the callback once the user authorizes your application
  def linkedin_authorization_callback
    begin
      #Fetch the 'code' query parameter from the callback
      code = params[:code]
      state = params[:state]

      if !state.eql?(Settings.linkedin.STATE)
        #Reject the request as it may be a result of CSRF
      else
        logger.fatal request.protocol
        ofunnel_callback = Settings.linkedin.REDIRECT_URI
        #Get token object, passing in the authorization code from the previous step
        logger.fatal "Redirect to linkedin for getting token: #{code}  ,  #{ofunnel_callback}"
        token = linkedin_client.auth_code.get_token(code, :redirect_uri => ofunnel_callback)

        #Use token object to create access token for user
        #(this is required so that you provide the correct param name for the access token)
        access_token = OAuth2::AccessToken.new(linkedin_client, token.token, {
            :mode => :query,
            :param_name => "oauth2_access_token",
        })

        @allow_login = false
        if check_token_in_session
          if check_token_exists_in_ofunnel
            ofunnel_login(access_token)
          else
            reset_session
            redirect_to Settings.wrong_token_redirect
          end
        else
          unless session[:return_to].nil?
            if session[:return_to].match('/groups/join/')
              join_params = session[:return_to].split("/")
              params_length = join_params.length
              if check_join_token_exists_in_ofunnel(join_params[params_length - 2],join_params[params_length - 1])
                @allow_login = true
                ofunnel_login(access_token)
              else
                session[:return_to] = nil
                redirect_to Settings.wrong_token_redirect
              end
            elsif session[:return_to].match(/groups\/\d+\/join/)
              @allow_login = true
              ofunnel_login(access_token)
            else
              ofunnel_login(access_token)
            end
          else
            ofunnel_login(access_token)
          end
        end
      end
    rescue OAuth2::Error => e
      logger.fatal e.message
      logger.fatal e.backtrace.inspect
      reset_session
      redirect_to Settings.linkedin_auth_url and return
    end
  end

  def search_connections
  end

  def linkedin_search
    unless params[:query].nil? or params[:query].blank?
      query = URI.escape(params[:query])
      @multiple = params[:multiple]
      @type = params[:type]
      if @type == "COMPANY"
        query_array = params[:query].split(' at ')
        company = query_array[1].nil? ? query : query_array[1].strip
      else
        company = "null"
      end
      @offset = params[:offset].nil? ? 0 : params[:offset]
      @query = params[:query]

      get_connections_api_endpoint = "#{Settings.api_endpoints.GetConnectionsInCompany}/#{@type}/#{company}/#{query}/#{current_user}/#{@offset}"
      get_tags_api_endpoint = "#{Settings.api_endpoints.GetUserTagsFromUserId}/#{current_user_id}"
      google_api_endpoint = "#{Settings.api_endpoints.GetGmailConnectionsWithUserId}/#{current_user_id}"
      facebook_api_endpoint = "#{Settings.api_endpoints.GetFacebookConnectionsWithUserId}/#{current_user_id}"
      get_connections_response = nil
      get_tags_response = nil
      google_api_response = nil
      facebook_api_response = nil

      hydra = Typhoeus::Hydra.hydra
      get_connections_request = Typhoeus::Request.new(get_connections_api_endpoint)
      get_tags_request = Typhoeus::Request.new(get_tags_api_endpoint)
      google_api_request = Typhoeus::Request.new(google_api_endpoint)
      facebook_api_request = Typhoeus::Request.new(facebook_api_endpoint)

      hydra.queue get_connections_request
      hydra.queue get_tags_request
      get_connections_request.on_complete do |response|
        get_connections_response = response
      end
      get_tags_request.on_complete do |response|
        get_tags_response = response
      end

      if (check_google_session and @type == "COMPANY")
        hydra.queue google_api_request
        google_api_request.on_complete do |response|
          google_api_response = response
        end
      end
      if (check_facebook_session and @type == "COMPANY")
        hydra.queue facebook_api_request
        facebook_api_request.on_complete do |response|
          facebook_api_response = response
        end
      end

      hydra.run

      @offset = @offset.to_i + 25
      if get_connections_response.success? && !api_contains_error("GetConnectionsInCompany", get_connections_response)
        get_connections_api_response = JSON.parse(get_connections_response.response_body)
        connections = get_connections_api_response["GetConnectionsInCompanyResult"]
        unless connections.nil?
          @direct_connections = connections["firstlevelpersons"]
          @indirect_connections = connections["secondlevelpersons"]
          @connections_remaining = connections["connectionsRemaining"].to_i
        else
          @direct_connections,@indirect_connections = nil
          @connections_remaining = 0
        end
      end
      if get_tags_response.success? && !api_contains_error("GetUserTagsFromUserId", get_tags_response)
        get_tags_api_response = JSON.parse(get_tags_response.response_body)
        tags = get_tags_api_response["GetUserTagsFromUserIdResult"]
        unless tags.nil?
          @user_tags = tags["userTagsDetails"]
        else
          @user_tags = nil
        end
      end

      @google_connections, @facebook_connections = nil
      if (check_google_session and @type == "COMPANY")
        if google_api_response.success? && !api_contains_error("GetGmailConnectionsWithUserId", google_api_response)
          google_api_response = JSON.parse(google_api_response.response_body)
          @google_connections = google_api_response["GetGmailConnectionsWithUserIdResult"]
        end
      end

      if (check_facebook_session and @type == "COMPANY")
        if facebook_api_response.success? && !api_contains_error("GetFacebookConnectionsWithUserId", facebook_api_response)
          facebook_api_response = JSON.parse(facebook_api_response.response_body)
          @facebook_connections = facebook_api_response["GetFacebookConnectionsWithUserIdResult"]
        end
      end

      if request.xhr?
        render :partial => "linkedin/more_company_results"
      end
    else
      redirect_to root_path
    end
  end

  def connections
    @id = params[:id]
    @status = params[:status]
    get_requests_flag = (@id != "nil" && @status != "nil")
    linkedin_api_endpoint = "#{Settings.api_endpoints.GetLinkedInList}/#{current_user_id}"
    request_details_api_endpoint = "#{Settings.api_endpoints.GetRequestForRequestId}/#{@id}"
    google_api_endpoint = "#{Settings.api_endpoints.GetGmailConnectionsWithUserId}/#{current_user_id}"
    facebook_api_endpoint = "#{Settings.api_endpoints.GetFacebookConnectionsWithUserId}/#{current_user_id}"

    linkedin_api_response = nil
    request_details_api_response = nil
    google_api_response = nil
    facebook_api_response = nil

    hydra = Typhoeus::Hydra.hydra
    linkedin_api_request = Typhoeus::Request.new(linkedin_api_endpoint)
    request_details_api_request = Typhoeus::Request.new(request_details_api_endpoint)
    google_api_request = Typhoeus::Request.new(google_api_endpoint)
    facebook_api_request = Typhoeus::Request.new(facebook_api_endpoint)

    hydra.queue linkedin_api_request
    linkedin_api_request.on_complete do |response|
      linkedin_api_response = response
    end
    if get_requests_flag
      hydra.queue request_details_api_request
      request_details_api_request.on_complete do |response|
        request_details_api_response = response
      end
    end
    if check_google_session
      hydra.queue google_api_request
      google_api_request.on_complete do |response|
        google_api_response = response
      end
    end
    if check_facebook_session
      hydra.queue facebook_api_request
      facebook_api_request.on_complete do |response|
        facebook_api_response = response
      end
    end
    hydra.run

    begin
      if linkedin_api_response.success? && !api_contains_error("GetLinkedInListWithUserId", linkedin_api_response)
        linkedin_api_response = JSON.parse(linkedin_api_response.response_body)
        @connections = linkedin_api_response["GetLinkedInListWithUserIdResult"]
        if @connections["error"].nil?
          @connections = @connections["values"]
        else
          @connections = nil
        end
      else
        @connections = nil
      end

      if get_requests_flag
        if request_details_api_response.success? && !api_contains_error("GetRequestForRequestId", request_details_api_response)
          @request = JSON.parse(request_details_api_response.response_body)
          if @request["GetRequestForRequestIdResult"]["error"].nil?
            @request = @request["GetRequestForRequestIdResult"]["requestDetails"][0]
          else
            @request = nil
          end
        else
          @request = nil
        end
      end

      @google_connections, @facebook_connections = nil
      if check_google_session
        if google_api_response.success? && !api_contains_error("GetGmailConnectionsWithUserId", google_api_response)
          google_api_response = JSON.parse(google_api_response.response_body)
          @google_connections = google_api_response["GetGmailConnectionsWithUserIdResult"]
        end
      end

      if check_facebook_session
        if facebook_api_response.success? && !api_contains_error("GetFacebookConnectionsWithUserId", facebook_api_response)
          facebook_api_response = JSON.parse(facebook_api_response.response_body)
          @facebook_connections = facebook_api_response["GetFacebookConnectionsWithUserIdResult"]
        end
      end
    rescue
      @connections, @request, @google_connections, @facebook_connections = nil
    end
    if get_requests_flag
      render :partial => "requests/accept_open_request_popup"
    else
      render :partial => "add_target_popup"
    end
  end

  def get_people_in_company
    query = params[:company]
    query_array = params[:company].split(' at ')
    company = query_array[1].nil? ? query : query_array[1].strip
    company = URI.escape(company)
    query = URI.escape(params[:query])
    get_people_in_company_api_endpoint = "#{Settings.api_endpoints.GetPersonsWithPersonName}/#{query}/#{current_user}"
    response = Typhoeus.get(get_people_in_company_api_endpoint)
    if response.success? && !api_contains_error("GetPersonsWithPersonName", response)
      get_people_in_company_api_response = JSON.parse(response.response_body)["GetPersonsWithPersonNameResult"]
      render :json => get_people_in_company_api_response
    else
      render :nothing => true
    end
  end

  def get_people_for_query
    query = URI.escape(params[:query])
    get_people_for_query_api_endpoint = "#{Settings.api_endpoints.GetPersonsWithPersonName}/#{query}/#{current_user}"
    response = Typhoeus.get(get_people_for_query_api_endpoint)
    if response.success? && !api_contains_error("GetPersonsWithPersonName", response)
      get_people_for_query_api_response = JSON.parse(response.response_body)["GetPersonsWithPersonNameResult"]
      render :json => get_people_for_query_api_response
    else
      render :nothing => true
    end
  end

  def multiple_company_search
    @company = params[:company]
    @tag_id = params[:tag_id]
    unless @company.nil? or @tag_id.nil?
      get_company_network_group_connections_api_endpoint = URI.escape("#{Settings.api_endpoints.GetCompanyNetworkGroupConnections}/#{current_user_id}/#{@tag_id}/#{@company}")
      response = Typhoeus.get(get_company_network_group_connections_api_endpoint)
      if response.success? && !api_contains_error("GetCompanyNetworkGroupConnections", response)
        get_company_network_group_connections_response = JSON.parse(response.response_body)["GetCompanyNetworkGroupConnectionsResult"]
        @companies = get_company_network_group_connections_response["companyNames"]
        @connections = get_company_network_group_connections_response["connections"]
      else
        @companies, @connections = nil
      end
    else
      redirect_to root_path
    end
  end

  def multiple_company_search_results
    @company = params[:company]
    @tag_id = params[:tag_id]
    unless @company.nil? or @tag_id.nil?
      companies = {
          :companies => JSON.parse(params[:companies])
      }.to_json
      @selected_accounts = params[:accounts].split(',') unless params[:accounts].nil? or params[:accounts].blank?
      connections = JSON.parse(params[:connections]) unless params[:connections].nil? or params[:connections].blank?
      @offset = params[:offset].nil? ? 0 : params[:offset]

      company_names_json = {
          :companyNames => []
      }
      JSON.parse(params[:companies]).each do |company|
        company_names_json[:companyNames].push(
            {
                :name => company["company"]
            }
        )
      end

      connections_json = {
          :connections => []
      }
      connections.each do |connection|
        connections_json[:connections].push(
            {
                :connectionId=> connection["connectionId"],
                :name => connection["connectionName"]
            }
        )
      end

      get_connection_in_multiple_companies_api_endpoint = "#{Settings.api_endpoints.GetConnectionsInMultipleCompanies}"
      persist_company_network_connections_api_endpoint = "#{Settings.api_endpoints.PersistCompanyNetworkConnections}"
      google_api_endpoint = "#{Settings.api_endpoints.GetGmailConnectionsWithUserId}/#{current_user_id}"
      facebook_api_endpoint = "#{Settings.api_endpoints.GetFacebookConnectionsWithUserId}/#{current_user_id}"
      get_connection_in_multiple_companies_api_response = nil
      persist_company_network_connections_api_response = nil
      google_api_response = nil
      facebook_api_response = nil

      hydra = Typhoeus::Hydra.hydra
      get_connection_in_multiple_companies_api_request = Typhoeus::Request.new(
          get_connection_in_multiple_companies_api_endpoint,
          method: :post,
          body: {
              companyNamesJson: companies,
              linkedInId: current_user
          })
      persist_company_network_connections_api_request = Typhoeus::Request.new(
          persist_company_network_connections_api_endpoint,
          method: :post,
          body: {
              userId: current_user_id,
              tagId: @tag_id,
              connectionsJson: connections_json.to_json,
              companyNamesJson: company_names_json.to_json
          })
      google_api_request = Typhoeus::Request.new(google_api_endpoint)
      facebook_api_request = Typhoeus::Request.new(facebook_api_endpoint)

      hydra.queue get_connection_in_multiple_companies_api_request
      hydra.queue persist_company_network_connections_api_request

      get_connection_in_multiple_companies_api_request.on_complete do |response|
        get_connection_in_multiple_companies_api_response = response
      end
      persist_company_network_connections_api_request.on_complete do |response|
        persist_company_network_connections_api_response = response
      end

      if check_google_session
        hydra.queue google_api_request
        google_api_request.on_complete do |response|
          google_api_response = response
        end
      end
      if check_facebook_session
        hydra.queue facebook_api_request
        facebook_api_request.on_complete do |response|
          facebook_api_response = response
        end
      end

      hydra.run

      @offset = @offset.to_i + 25
      if get_connection_in_multiple_companies_api_response.success? && !api_contains_error("GetConnectionsInMultipleCompanies", get_connection_in_multiple_companies_api_response)
        multiple_companies_api_response = JSON.parse(get_connection_in_multiple_companies_api_response.response_body)["GetConnectionsInMultipleCompaniesResult"]
        @Company_result = multiple_companies_api_response["PeopleSearchSortedData"]
      else
        @Company_result = nil
      end

      @google_connections, @facebook_connections = nil
      if check_google_session
        if google_api_response.success? && !api_contains_error("GetGmailConnectionsWithUserId", google_api_response)
          google_api_response = JSON.parse(google_api_response.response_body)
          @google_connections = google_api_response["GetGmailConnectionsWithUserIdResult"]
        end
      end

      if check_facebook_session
        if facebook_api_response.success? && !api_contains_error("GetFacebookConnectionsWithUserId", facebook_api_response)
          facebook_api_response = JSON.parse(facebook_api_response.response_body)
          @facebook_connections = facebook_api_response["GetFacebookConnectionsWithUserIdResult"]
        end
      end

      @connections = nil
      @updated_connections = connections_json[:connections]
    else
      redirect_to root_path
    end
  end

  def remove_company
    target_account_id = params[:target_account_id]
    api_endpoint = "#{Settings.api_endpoints.DeleteTargetAccount}"
    response = Typhoeus.post(api_endpoint, body: {
        userId: current_user_id,
        targetAccountId: target_account_id
    })

    api_response = {"error" => true}
    if response.success? && !api_contains_error("DeleteTargetAccount", response)
      response = JSON.parse(response.response_body)["DeleteTargetAccountResult"]
      if response["isTargetAccountDeleted"] == true
        api_response = response
      end
    end
    render :json => api_response.to_json
  end

  def add_relationships
    unless params[:alertJson].blank?
      target_accounts = JSON.parse(params[:alertJson])
      alert_json = {
          :alert => []
      }

      alert_array = []
      target_accounts.each do |target|
        alert_array.push(
            {
                :type => target["type"],
                :name => target["name"],
                :alertId => target["alertId"]
            }
        )
      end

      alert_json[:alert] = alert_array

      persist_company_network_alert_api_endpoint = "#{Settings.api_endpoints.PersistNetworkAlerts}"
      get_alerts_recipient_api_endpoint = "#{Settings.api_endpoints.GetRecipientsEmailForNetworkAlerts}/#{current_user_id}"
      persist_company_network_alert_response = nil
      get_alerts_recipient_response = nil

      hydra = Typhoeus::Hydra.hydra
      persist_company_network_alert_request = Typhoeus::Request.new(
          persist_company_network_alert_api_endpoint,
          method: :post,
          body: {
              userId: current_user_id,
              alertJson: alert_json.to_json
          })
      get_alerts_recipient_request = Typhoeus::Request.new(get_alerts_recipient_api_endpoint)

      hydra.queue persist_company_network_alert_request
      hydra.queue get_alerts_recipient_request

      persist_company_network_alert_request.on_complete do |response|
        persist_company_network_alert_response = response
      end

      get_alerts_recipient_request.on_complete do |response|
        get_alerts_recipient_response = response
      end

      hydra.run

      @emails = nil
      if get_alerts_recipient_response.success? && !api_contains_error("GetRecipientsEmailForNetworkAlerts", get_alerts_recipient_response)
        api_response = JSON.parse(get_alerts_recipient_response.response_body)["GetRecipientsEmailForNetworkAlertsResult"]
        @emails = api_response["recipientEmailDetails"] if api_response["error"] == nil
      end

      if mobile_device
        render "responsive_add_relationships", :layout => "responsive_relationships"
      else
        render "add_relationships", :layout => "relationships"
      end

    else
      redirect_to discover_relationships_path and return
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
    render :json => api_response.to_json
  end

  protected

  def set_tab
    session[:selected_tab] = "results"
    session[:active_tab] = ""
  end

  def linkedin_client
    OAuth2::Client.new(
        Settings.linkedin.API_KEY,
        Settings.linkedin.API_SECRET,
        :authorize_url => "/uas/oauth2/authorization?response_type=code",
        :token_url => "/uas/oauth2/accessToken",
        :site => "https://www.linkedin.com"
    )
  end

  def last_company(positions)
    return false if positions.nil?
    if positions["_total"].to_i > 0
      return positions["values"][0]["company"]["name"]
    else
      return nil
    end
  end

  def last_school(educations)
    return false if educations.nil?
    if educations["_total"].to_i > 0
      return educations["values"][0]["schoolName"]
    else
      return nil
    end
  end

  def ofunnel_login(access_token)
    session[:linkedin_token] = access_token.token
    back_url = session[:return_to] || cookies.signed[:return_to]
    session[:return_to] = nil
    #Use the access token to make an authenticated API call
    response = access_token.get('https://www.linkedin.com/v1/people/~:(id,first-name,last-name,public-profile-url,picture-url,email-address,educations,positions,headline,location:(name),skills)?format=json')
    profile = JSON.parse(response.body)
    ofunnel_user_type = "ALERT"
    unless back_url.nil?
      if back_url.match(/requests/)
        ofunnel_user_type = "OFUNNEL"
      elsif back_url.match(/hootsuite/)
        ofunnel_user_type = "HOOTSUITE"
      end
    end

    check_ofunnel_user_exists_endpoint = "#{Settings.api_endpoints.CheckOFunnelUserExist}/#{profile["id"]}/#{profile["emailAddress"]}"
    check_ofunnel_user_exists_response = Typhoeus.get(check_ofunnel_user_exists_endpoint)

    if check_ofunnel_user_exists_response.success? && !api_contains_error("CheckOFunnelUserExist", check_ofunnel_user_exists_response)
      check_ofunnel_user_exists_response = JSON.parse(check_ofunnel_user_exists_response.response_body)["CheckOFunnelUserExistResult"]
      unless check_ofunnel_user_exists_response["isOFunnelUser"]
        session[:welcome_wizard] = true
      end
    end

    user_data = {
        :lnkdnId => profile["id"],
        :accessToken => access_token.token,
        :firstName => profile["firstName"],
        :lastName => profile["lastName"],
        :profileUrl => profile["publicProfileUrl"],
        :profilePictureUrl => profile["pictureUrl"],
        :email => profile["emailAddress"],
        :educationDetailsJson => {
            'educations' => profile["educations"]
        }.to_json,
        :positionDetailsJson => {
            'positions' => profile["positions"]
        }.to_json,
        :headline => profile["headline"],
        :location => profile["location"]["name"],
        :userType => ofunnel_user_type
    }

    api_endpoint = "#{Settings.api_endpoints.AddOFunnelUser}"
    add_user_response = Typhoeus.post(api_endpoint, body: user_data)
    if add_user_response.success? && !api_contains_error("AddOFunnelUser", add_user_response)
      user_data[:position] = profile["positions"]["_total"].to_i > 0 ? profile["positions"]["values"][0]["title"] : ""
      user_data[:location] = profile["location"]
      user_data[:skills] = profile["skills"]
      set_current_user(profile["id"])
      set_current_user_profile(user_data)
      add_user_response = JSON.parse(add_user_response.response_body)["AddOFunnelUserResult"]
      set_current_user_id(add_user_response["userId"])
      set_current_user_score(add_user_response["score"])
      # Commented due to bug#324
      #set_show_ofunnel_help(true)
      if check_token_in_session
        if session[:token_user_id].nil?
          mark_token_used(session[:token])
          redirect_to( back_url.nil? ? alerts_path : back_url) and return
        else
          if session[:token_user_id] == current_user_id
            redirect_to( back_url.nil? ? alerts_path : back_url) and return
          else
            reset_session
            redirect_to Settings.wrong_token_redirect and return
          end
          session[:token] = nil
        end
      else
        redirect_to( back_url.nil? ? alerts_path : back_url) and return
      end
    else
      redirect_to root_path and return
    end
  end

  def check_token_in_session
    return session[:token].nil? ? false : true
  end

  def check_token_exists_in_ofunnel
    token_api_endpoint = "#{Settings.api_endpoints.IsValidSignUpToken}"
    token_api_response = Typhoeus.post(token_api_endpoint, body: {signUpToken:"#{session[:token]}"})
    if token_api_response.success? && ! api_contains_error("IsValidSignUpToken", token_api_response)
      token_response = JSON.parse(token_api_response.response_body)["IsValidSignUpTokenResult"]
      if token_response["isTokenExist"]
        if token_response["isTokenUsed"]
          session[:token_user_id] = token_response["userId"]
        end
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def check_join_token_exists_in_ofunnel(invite_id,token)
    token_api_endpoint = "#{Settings.api_endpoints.CheckGroupJoinInvitationToken}"
    token_api_response = Typhoeus.post(token_api_endpoint, body: {inviteId:invite_id,groupInviteToken:token})

    if token_api_response.success? && ! api_contains_error("CheckGroupJoinInvitationToken", token_api_response)
      token_response = JSON.parse(token_api_response.response_body)["CheckGroupJoinInvitationTokenResult"]
      if token_response["isValidToken"]
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def mark_token_used(token)
    mark_used_token_api_endpoint = "#{Settings.api_endpoints.MarkTokenAsUsedRequest}"
    mark_used_token_api_response = Typhoeus.post(mark_used_token_api_endpoint, body: {
        token: token,
        userId: "#{current_user_id}"
    })
    if mark_used_token_api_response.success? && !api_contains_error("MarkTokenAsUsed", mark_used_token_api_response)
      session[:token_user_id] = nil
      return true
    else
      return false
    end
  end

  def delete_token
    delete_token_api_endpoint = "#{Settings.api_endpoints.DeleteSignUpUserToken}"
    delete_token_api_response = Typhoeus.post(delete_token_api_endpoint, body: {
        signUpToken: "#{session[:token]}"
    })
    if delete_token_api_response.success? && ! api_contains_error("DeleteSignUpUserToken", delete_token_api_response)
      return JSON.parse(delete_token_api_response.response_body)["DeleteSignUpUserTokenResult"]["isTokenRemoved"]
    else
      false
    end
  end

  def open_spreadsheet(file)
    case File.extname(file.original_filename)
      when ".csv"
      then Roo::Csv.new(file.path, nil, :ignore)
      when ".xls"
      then Roo::Excel.new(file.path, nil, :ignore)
      when ".xlsx"
      then Roo::Excelx.new(file.path, nil, :ignore)
      else
        return nil
    end
  end

end
