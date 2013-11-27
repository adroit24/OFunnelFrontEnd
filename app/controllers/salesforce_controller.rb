class SalesforceController < ApplicationController

  before_filter :check_current_user
  layout "salesforce"

  def authorize_with_salesforce
    session[:salesforce_token] = nil
    #Redirect your user in order to authenticate
    redirect_url = salesforce_client.auth_code.authorize_url(
        :redirect_uri => Settings.salesforce.REDIRECT_URI
    )
    logger.fatal "Redirect to salesforce for first time: #{redirect_url}"
    redirect_to redirect_url
  end

  # This method will handle the callback once the user authorizes your application
  def salesforce_authorization_callback
    begin
      back_url = session[:return_to].blank? ? salesforce_explore_relationship_path : session[:return_to]
      session[:return_to] = nil
      #Fetch the 'code' query parameter from the callback
      code = params[:code]

      #Get token object, passing in the authorization code from the previous step
      logger.fatal "Redirect to salesforce for getting token: #{code}  ,  #{Settings.salesforce.REDIRECT_URI}"
      token = salesforce_client.auth_code.get_token(code, {:redirect_uri => Settings.salesforce.REDIRECT_URI})
      logger.fatal "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      logger.fatal "User Id ==> #{current_user_id}"
      logger.fatal "Refresh Token ==>> #{token.refresh_token}"
      logger.fatal "OAuth Token ==>> #{token.token}"
      logger.fatal "Instance URL ==>> #{token.params['instance_url']}"
      logger.fatal "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      api_endpoint = "#{Settings.api_endpoints.LoginOnSalesForce}"
      response = Typhoeus.post(api_endpoint, body: {
          userId: current_user_id,
          accessToken: token.token,
          instanceUrl: token.params['instance_url']
      })

      if response.success? && !api_contains_error("LoginOnSalesForce", response)
        add_access_token_api_response = JSON.parse(response.response_body)
        add_access_token_api_response = add_access_token_api_response["LoginOnSalesForceResult"]
        if add_access_token_api_response["isUserLogedIn"] == true
          session[:salesforce_token] = token.token
        end
      end
      redirect_to back_url, :protocol => 'http'
    rescue OAuth2::Error => e
      logger.fatal e.message
      logger.fatal e.backtrace.inspect
      redirect_to Settings.salesforce_auth_url
    end
  end

  def explore_relationship
    if check_salesforce_session and !params[:q].blank?
      salesforce_query = params[:q]
      salesforce_query_array = salesforce_query.split('$')
      if salesforce_query_array.length == 3
        @company = salesforce_query_array[0].gsub("+"," ")
        @account_id = salesforce_query_array[1]
        @organisation = salesforce_query_array[2]
        @type = "COMPANY"
        @offset = params[:offset].nil? ? 0 : params[:offset]
        @query = @company
        @tag_id = nil
        @selected_accounts = []
        @selected_accounts.push(@company)
        companies = {
            :companies => [
                {
                    :company => @company,
                    :start => 0
                }
            ]
        }.to_json

        api_endpoint = "#{Settings.api_endpoints.AddMemberToExistingGroupOrCreateGroup}"
        response = Typhoeus.post(api_endpoint, body: {
            userId: current_user_id,
            tagName: @organisation
        })

        if response.success? && !api_contains_error("AddMemberToExistingGroupOrCreateGroup", response)
          add_access_token_api_response = JSON.parse(response.response_body)
          add_access_token_api_response = add_access_token_api_response["AddMemberToExistingGroupOrCreateGroupResult"]
          @tag_id = add_access_token_api_response["tagId"]
        end

        get_connection_in_multiple_companies_api_endpoint = "#{Settings.api_endpoints.GetConnectionsInMultipleCompanies}"
        get_company_network_group_connections_api_endpoint = URI.escape("#{Settings.api_endpoints.GetCompanyNetworkGroupConnections}/#{current_user_id}/#{@tag_id}/#{@company}")
        get_salesforce_connections_api_endpoint = URI.escape("#{Settings.api_endpoints.GetSalesForceConnections}/#{current_user_id}/#{@account_id}")
        persist_company_network_connections_api_endpoint = "#{Settings.api_endpoints.PersistCompanyNetworkConnections}"
        get_connection_in_multiple_companies_api_response = nil
        get_company_network_group_connections_response = nil
        get_salesforce_connections_api_response = nil
        persist_company_network_connections_api_response = nil

        hydra = Typhoeus::Hydra.hydra
        get_connection_in_multiple_companies_api_request = Typhoeus::Request.new(
            get_connection_in_multiple_companies_api_endpoint,
            method: :post,
            body: {
                companyNamesJson: companies,
                linkedInId: current_user
            })

        get_company_network_group_connections_request = Typhoeus::Request.new(get_company_network_group_connections_api_endpoint)
        get_salesforce_connections_api_request = Typhoeus::Request.new(get_salesforce_connections_api_endpoint)
        hydra.queue get_connection_in_multiple_companies_api_request
        hydra.queue get_company_network_group_connections_request
        hydra.queue get_salesforce_connections_api_request
        get_connection_in_multiple_companies_api_request.on_complete do |response|
          get_connection_in_multiple_companies_api_response = response
        end
        get_company_network_group_connections_request.on_complete do |response|
          get_company_network_group_connections_response = response
        end
        get_salesforce_connections_api_request.on_complete do |response|
          get_salesforce_connections_api_response = response
        end
        hydra.run
        @offset = @offset.to_i + 25
        if get_connection_in_multiple_companies_api_response.success? && !api_contains_error("GetConnectionsInMultipleCompanies", get_connection_in_multiple_companies_api_response)
          multiple_companies_api_response = JSON.parse(get_connection_in_multiple_companies_api_response.response_body)["GetConnectionsInMultipleCompaniesResult"]
          @Company_result = multiple_companies_api_response["PeopleSearchSortedData"]
        else
          @Company_result = nil
        end

        if get_company_network_group_connections_response.success? && !api_contains_error("GetCompanyNetworkGroupConnections", get_company_network_group_connections_response)
          get_company_network_group_connections_response = JSON.parse(get_company_network_group_connections_response.response_body)["GetCompanyNetworkGroupConnectionsResult"]
          companies = get_company_network_group_connections_response["companyNames"]
          @connections = get_company_network_group_connections_response["connections"]
          persist_company_network_connections_api_response = Typhoeus.post(persist_company_network_connections_api_endpoint,
                                                                           body: {
                                                                               userId: current_user_id,
                                                                               tagId: @tag_id,
                                                                               connectionsJson: @connections.to_json,
                                                                               companyNamesJson: {
                                                                                   :companyNames => [
                                                                                       :name => @company
                                                                                   ]
                                                                               }.to_json
                                                                           })

        else
          @connections = nil
        end

        @salesforce_contact_hash = {}
        @salesforce_contacts = []
        if get_salesforce_connections_api_response.success? && !api_contains_error("GetSalesForceConnections", get_salesforce_connections_api_response)
          get_salesforce_connections_api_response = JSON.parse(get_salesforce_connections_api_response.response_body)["GetSalesForceConnectionsResult"]
          salesforce_contacts_json = get_salesforce_connections_api_response["salesForceContacts"]
          unless salesforce_contacts_json.nil? or salesforce_contacts_json["totalSize"].to_i < 1
            @salesforce_contacts = salesforce_contacts_json["records"].collect {|contact|
              contact["Name"].downcase
            }
            salesforce_contacts_json["records"].each do |contact|
              @salesforce_contact_hash[contact["Name"].downcase.to_sym] = contact["Id"]
            end
          end
        end
      else
        redirect_to root_path
      end
    end
  end

  def show_more
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
    @account_id = params[:account_id]
    unless params[:salesforce_contacts].nil? or params[:salesforce_contacts].blank?
      @salesforce_contacts = params[:salesforce_contacts].split(',')
    else
      @salesforce_contacts = []
    end
    unless params[:salesforce_contact_hash].nil? or params[:salesforce_contact_hash].blank?
      @salesforce_contact_hash = eval(params[:salesforce_contact_hash])
    else
      @salesforce_contact_hash = {}
    end
    get_connections_api_endpoint = "#{Settings.api_endpoints.GetConnectionsInCompany}/#{@type}/#{company}/#{query}/#{current_user}/#{@offset}"
    get_connections_response = nil

    hydra = Typhoeus::Hydra.hydra
    get_connections_request = Typhoeus::Request.new(get_connections_api_endpoint)
    hydra.queue get_connections_request
    get_connections_request.on_complete do |response|
      get_connections_response = response
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
    render :partial => "show_more"
  end

  def add_salesforce_connection
    api_endpoint = "#{Settings.api_endpoints.AddSalesForceConnection}"
    response = Typhoeus.post(api_endpoint, body: {
        userId: current_user_id,
        salesForceAccountId: params[:salesForceAccountId],
        #salesForceAccountName: params[:salesForceAccountName],
        firstName: params[:firstName],
        lastName: params[:lastName],
        profileUrl: params[:profileUrl],
        profilePictureUrl: params[:profilePictureUrl],
        headline: params[:headline],
        location: params[:location],
        connectedVia: current_user_name
    })

    if response.success? && !api_contains_error("AddSalesForceConnection", response)
      add_access_token_api_response = JSON.parse(response.response_body)
      add_access_token_api_response = add_access_token_api_response["AddSalesForceConnectionResult"]
      api_response = add_access_token_api_response
    else
      api_response = {"error" => true}
    end
    render :json => api_response.to_json
  end

  def mark_connected
    connected_id_json = JSON.parse(params[:contactsIdJson])

    mark_contact_connected_api_endpoint = "#{Settings.api_endpoints.MarkedContactConnected}"
    mark_contact_connected_api_response = Typhoeus.post(mark_contact_connected_api_endpoint, body: {
        userId: current_user_id,
        contactsIdJson: connected_id_json.to_json
    })

    if mark_contact_connected_api_response.success? && !api_contains_error("MarkedContactConnected", mark_contact_connected_api_response)
      mark_contact_connected_api_response = JSON.parse(mark_contact_connected_api_response.response_body)
      mark_contact_connected_api_response = mark_contact_connected_api_response["MarkedContactConnectedResult"]
      api_response = mark_contact_connected_api_response
    else
      api_response = {"error" => true}
    end
    render :json => api_response.to_json
  end

  def import_salesforce
    type = params[:type].nil? ? session[:sf_import_type] : params[:type]
    session[:sf_import_type] = nil
    unless session[:salesforce_token].nil?
      api_endpoint = "#{Settings.api_endpoints.ImportSalesForceCompaniesFromLeadOrAccount}/#{current_user_id}/#{type}"
      response = Typhoeus.get(api_endpoint)

      if response.success? && !api_contains_error("ImportSalesForceCompaniesFromLeadOrAccount", response)
        api_response = JSON.parse(response.response_body)["ImportSalesForceCompaniesFromLeadOrAccountResult"]
        if api_response["isCompaniesPersisted"] == true
          flash[:notice] = "Target Accounts have been imported."
        end
      end

      redirect_to alerts_path
    else
      session[:return_to] = current_url
      session[:sf_import_type] = type
      redirect_to authorize_with_salesforce_path
    end
  end

  def add_target_account
    unless params[:q].blank?
      alert_json = {
          :targetAccount => [
              {
                  :filterType => "COMPANY",
                  :targetName => params[:q],
                  :targetAccountId => nil,
                  :secondLevelFilterDetails => nil
              }
          ]
      }

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
      p persist_company_network_alert_response
      if persist_company_network_alert_response.success? && !api_contains_error("PersistNetworkAlerts", persist_company_network_alert_response)
        api_response = JSON.parse(persist_company_network_alert_response.response_body)["PersistNetworkAlertsResult"]
        status = api_response["isNetworkAlertPersisted"] == true ? nil : true
      end
      render :json => {"error" => status} and return
    else
      render :json => {"error" => true} and return
    end
  end

  protected

  def salesforce_client
    OAuth2::Client.new(
        Settings.salesforce.CLIENT_ID,
        Settings.salesforce.CLIENT_SECRET,
        :authorize_url => "/services/oauth2/authorize",
        :token_url => "/services/oauth2/token",
        :site => "https://login.salesforce.com"
    )
  end

end
