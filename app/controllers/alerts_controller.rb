class AlertsController < ApplicationController
  require 'mime/types' #mime-types gem
  require 'roo'

  layout "relationships"
  before_filter :check_current_user

  def index
    #if mobile_device
    #  @count = 999999
    #else
    @count = 25
    #end
    @offset = params[:offset].nil? ? 0 : params[:offset].to_i
    @total_pages = 0
    get_company_network_alert_api_endpoint = URI.escape("#{Settings.api_endpoints.GetNetworkAlerts}/#{current_user_id}/#{@offset}/#{@count}")
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
    @page_remaining = (@total_pages > 0 and @total_pages > @current_page) ? (@total_pages - @current_page) : 0

    @similar = nil
    unless @alerts.blank?
      @first_alert, @first_alert_index, @first_alert_filter_type = nil
      @alerts.each_with_index do |alert,i|
        @first_alert_filter_type = alert["filterType"]
        if @first_alert_filter_type.eql? "PERSON"
          next
        else
          @first_alert = alert
          @first_alert_index = i
          break
        end
      end
      unless @first_alert.blank?
        target_account_id = @first_alert["targetAccountId"]
        similar_count = 5
        if @first_alert_filter_type.eql? "COMPANY"
          get_similar_companies_api_endpoint = URI.escape("#{Settings.api_endpoints.GetSimilarCompaniesForTargetAccountId}/#{current_user_id}/#{target_account_id}/#{similar_count}")
          response = Typhoeus.get(get_similar_companies_api_endpoint)
          @similar = JSON.parse(response.response_body)["GetSimilarCompaniesForTargetAccountIdResult"]
        elsif @first_alert_filter_type.eql? "ROLE"
          get_similar_roles_api_endpoint = URI.escape("#{Settings.api_endpoints.GetSimilarRolesForTargetAccountId}/#{current_user_id}/#{target_account_id}/#{similar_count}")
          response = Typhoeus.get(get_similar_roles_api_endpoint)
          @similar = JSON.parse(response.response_body)["GetSimilarRolesForTargetAccountIdResult"]
        end
      end
    end

    if mobile_device
      render "responsive_discover_relationships", :layout => "responsive_relationships" and return
    end
  end

  def similar_companies
    target_id = params[:targetId]
    target_type = params[:targetType]
    target_text = params[:targetText]
    @first_alert = {}
    @first_alert["targetAccountId"] = target_id
    @first_alert_filter_type = target_type.upcase
    @first_alert["targetName"] = target_text
    similar_count = 5
    get_similar_companies_api_endpoint = URI.escape("#{Settings.api_endpoints.GetSimilarCompaniesForTargetAccountId}/#{current_user_id}/#{target_id}/#{similar_count}")
    response = Typhoeus.get(get_similar_companies_api_endpoint)
    @similar = JSON.parse(response.response_body)["GetSimilarCompaniesForTargetAccountIdResult"]
    render :partial => "similar_companies", :layout => false
  end

  def similar_roles
    target_id = params[:targetId]
    target_type = params[:targetType]
    target_text = params[:targetText]
    @first_alert = {}
    @first_alert["targetAccountId"] = target_id
    @first_alert_filter_type = target_type.upcase
    @first_alert["targetName"] = target_text
    similar_count = 5
    get_similar_roles_api_endpoint = URI.escape("#{Settings.api_endpoints.GetSimilarRolesForTargetAccountId}/#{current_user_id}/#{target_id}/#{similar_count}")
    response = Typhoeus.get(get_similar_roles_api_endpoint)
    @similar = JSON.parse(response.response_body)["GetSimilarRolesForTargetAccountIdResult"]
    render :partial => "similar_roles", :layout => false
  end

  def add_similar_alert
    alert = []
    status = false
    second_level_filters = nil
    get_alert_api_endpoint = URI.escape("#{Settings.api_endpoints.GetNetworkAlertWithTargetAccountId}/#{current_user_id}/#{params[:similarTargetId]}")
    response = Typhoeus.get(get_alert_api_endpoint)
    if response.success? && !api_contains_error("GetNetworkAlertWithTargetAccountId", response)
      get_alert_api_response = JSON.parse(response.response_body)["GetNetworkAlertWithTargetAccountIdResult"]
      alert = get_alert_api_response["targetAccount"]
      second_level_filters = alert["secondLevelFilterDetails"] unless alert.nil?
    end

    filter_type = alert["filterType"]
    alert_json = {
        :targetAccount => []
    }

    alert_array = [{
                       :filterType => filter_type,
                       :targetName => params[:targetText],
                       :targetAccountId => nil,
                       :secondLevelFilterDetails => second_level_filters
                   }]

    alert_json[:targetAccount] = alert_array

    persist_network_alert_api_endpoint = "#{Settings.api_endpoints.PersistNetworkAlerts}"
    response = Typhoeus.post(
        persist_network_alert_api_endpoint,
        body: {
            userId: current_user_id,
            alertJson: alert_json.to_json
        })

    new_target_id = nil
    if response.success? && !api_contains_error("PersistNetworkAlerts", response)
      api_response = JSON.parse(response.response_body)["PersistNetworkAlertsResult"]
      if api_response["isNetworkAlertPersisted"].eql? true
        status = api_response["status"]
        new_target_id = api_response["targetAccountId"]
      end
    end

    @new_alert
    get_alert_api_endpoint = URI.escape("#{Settings.api_endpoints.GetNetworkAlertWithTargetAccountId}/#{current_user_id}/#{new_target_id}")
    response = Typhoeus.get(get_alert_api_endpoint)
    if response.success? && !api_contains_error("GetNetworkAlertWithTargetAccountId", response)
      get_alert_api_response = JSON.parse(response.response_body)["GetNetworkAlertWithTargetAccountIdResult"]
      @new_alert = get_alert_api_response["targetAccount"]
    end

    render :partial => "add_similar_alert", :layout => false
  end

  def new
    get_all_industries
    get_all_locations
  end

  def create
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
      if mobile_device
        hydra.queue get_alerts_recipient_request
      end

      persist_company_network_alert_request.on_complete do |response|
        persist_company_network_alert_response = response
      end

      get_alerts_recipient_request.on_complete do |response|
        get_alerts_recipient_response = response
      end

      hydra.run

      session[:track_alert_event] = true
      if mobile_device
        @emails = nil
        if get_alerts_recipient_response.success? && !api_contains_error("GetRecipientsEmailForNetworkAlerts", get_alerts_recipient_response)
          api_response = JSON.parse(get_alerts_recipient_response.response_body)["GetRecipientsEmailForNetworkAlertsResult"]
          @emails = api_response["recipientEmailDetails"] if api_response["error"] == nil
        end
      end

      if mobile_device
        render "responsive_thanks_you", :layout => "responsive_relationships" and return
      end
    end
    redirect_to alerts_path and return
  end

  def edit
    @alert = []
    get_all_industries
    get_all_locations
    get_alert_api_endpoint = URI.escape("#{Settings.api_endpoints.GetNetworkAlertWithTargetAccountId}/#{current_user_id}/#{params[:id]}")
    response = Typhoeus.get(get_alert_api_endpoint)
    if response.success? && !api_contains_error("GetNetworkAlertWithTargetAccountId", response)
      get_alert_api_response = JSON.parse(response.response_body)["GetNetworkAlertWithTargetAccountIdResult"]
      @alert = get_alert_api_response["targetAccount"]
    end
  end

  def update
  end

  def delete
    alert_id = params[:id]

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

  def industries
    error = 500
    industry_array = nil
    status = false
    unless params[:query].blank?
      begin
        industry_array = []
        industry_list = Industry.where("name LIKE ?",  "%#{params[:query]}%")
        unless industry_list.blank?
          industry_list.each do |industry_detail|
            industry_array.push({
                                    "industryId" => industry_detail.id,
                                    "industryType" => industry_detail.name
                                })
          end
        end
        error = nil
        status = true
      rescue
      end
      result = {
          "error" => error,
          "industry" => industry_array,
          "status" => status
      }
    end
    render :json => result.to_json and return
  end

  def locations
    error = 500
    location_array = nil
    status = false
    unless params[:query].blank?
      begin
        location_array = []
        location_list = Location.where("name like ?", "%#{params[:query]}%")
        unless location_list.blank?
          location_list.each do |location_detail|
            location_array.push({
                                    "state" => location_detail.name,
                                    "stateId" => location_detail.id
                                })
          end
        end
        error = nil
        status = true
      rescue
      end
      result = {
          "error" => error,
          "locations" => location_array,
          "status" => status
      }
    end
    render :json => result.to_json and return
  end

  def save_alert_changes
    status = {"ERROR" => true}
    flash[:notice] = "Error occurred, please try again."
    unless params["targetAccount"].blank?
      persist_network_alert_api_endpoint = "#{Settings.api_endpoints.PersistNetworkAlerts}"
      response = Typhoeus.post(
          persist_network_alert_api_endpoint,
          body: {
              userId: current_user_id,
              alertJson: {
                  "targetAccount" => JSON.parse(params["targetAccount"])
              }.to_json
          })

      if response.success? && !api_contains_error("PersistNetworkAlerts", response)
        api_response = JSON.parse(response.response_body)["PersistNetworkAlertsResult"]
        if api_response["isNetworkAlertPersisted"].eql? true
          session[:track_alert_event] = true
          flash[:notice] = "Changes saved."
        end
        status = {"ERROR" => false}
      end
    end
    render :json => status.to_json and return
  end

  def alerts_import_csv
    unless params[:csv].blank?
      begin
        if [
            "text/comma-separated-values",
            "text/csv",
            "application/csv",
            "application/excel",
            "application/vnd.ms-excel",
            "application/vnd.msexcel",
            "text/anytext",
            "application/vnd.ms-excel [official]",
            "application/msexcel",
            "application/x-msexcel",
            "application/x-ms-excel",
            "application/x-excel",
            "application/x-dos_ms_excel",
            "application/xls",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        ].include?(params[:csv].content_type)
          @company_array = []
          keywords_array = [
              "Company",
              "Companies",
              "Account",
              "Accounts",
              "Account Name",
              "Target Account",
              "Target Accounts"
          ].map(&:downcase)
          offset = 2
          limit = 500
          parsed_companies = 0
          spreadsheet = open_spreadsheet(params[:csv])
          unless spreadsheet.nil?
            total_companies = spreadsheet.to_a.length - 2
            header = spreadsheet.row(1)
            while (total_companies > parsed_companies) do
              (offset...(offset + limit)).each do |i|
                row = Hash[[header, spreadsheet.row(i)].transpose]
                row_arr = row.keys.reject { |key| key.blank? }
                original_keys = row_arr
                unless original_keys.nil?
                  keys = row_arr.map(&:downcase)
                  key = keys & keywords_array
                  index = keys.index(key[0])
                  unless index.nil?
                    original_key = original_keys[index]
                    company = row[original_key]
                    if company =~ /\S/
                      @company_array << company
                    end
                  end
                end
                parsed_companies += 1
              end
              if @company_array.blank?
                render :text => "NO_COMPANY" and return
              else
                alert_json = {
                    :targetAccount => []
                }

                alert_array = []
                @company_array.each do |target|
                  alert_array.push(
                      {
                          :filterType => "COMPANY",
                          :targetName => target,
                          :targetAccountId => nil,
                          :secondLevelFilterDetails => nil
                      }
                  )
                end
                alert_json[:targetAccount] = alert_array

                persist_company_network_alert_api_endpoint = "#{Settings.api_endpoints.PersistNetworkAlerts}"
                response = Typhoeus.post(
                    persist_company_network_alert_api_endpoint,
                    body: {
                        userId: current_user_id,
                        alertJson: alert_json.to_json
                    })
              end

              flash[:notice] = "Error occurred, please try again later."
              if response.success? && !api_contains_error("PersistNetworkAlerts", response)
                api_response = JSON.parse(response.response_body)["PersistNetworkAlertsResult"]
                if api_response["isNetworkAlertPersisted"] == true
                  session[:track_alert_event] = true
                  flash[:notice] = "Target Accounts have been imported. Click Submit to save and start receiving alerts."
                end
              end

              offset += 100
              @company_array = []
            end
            render :text => "RELOAD" and return
          end
        else
          render :text => "INVALID_FORMAT" and return
        end
      rescue
        render :text => "INVALID_FORMAT" and return
      end
    end
    render :text => "INVALID_FORMAT" and return
  end

  def add_recipients
    unless params[:recipientEmails].blank?
      recipient_emails = params[:recipientEmails]

      recipient_json = {
          :recipientEmail => []
      }
      recipient_array = []
      recipient_emails.each do |email|
        recipient_array.push(
            {
                :email => email
            }
        )
      end
      recipient_json[:recipientEmail] = recipient_array

      api_endpoint = "#{Settings.api_endpoints.SetRecipientEmailForNetworkAlerts}"
      response = Typhoeus.post(
          api_endpoint,
          body: {
              userId: current_user_id,
              recipientEmailJson: recipient_json.to_json
          })

      if response.success? && !api_contains_error("SetRecipientEmailForNetworkAlerts", response)
        api_response = JSON.parse(response.response_body)["SetRecipientEmailForNetworkAlertsResult"]
        if api_response["error"] == nil and api_response["isAddedRecipientEmail"] == true
          @emails = get_recipients
          respond_to do |format|
            format.js
          end
        else
          render :text => "ERROR" and return
        end
      else
        render :text => "ERROR" and return
      end
    else
      render :text => "ERROR" and return
    end
  end

  def remove_recipient
    recipient_id = params[:id]

    api_endpoint = "#{Settings.api_endpoints.DeleteRecipientEmail}/#{current_user_id}/#{recipient_id}"
    response = Typhoeus.get(api_endpoint)

    if response.success? && !api_contains_error("DeleteRecipientEmail", response)
      api_response = JSON.parse(response.response_body)["DeleteRecipientEmailResult"]
      if api_response["error"] == nil and api_response["isRecipientEmailDeleted"] == true
        @emails = get_recipients
        respond_to do |format|
          format.js
        end
      else
        render :text => "ERROR" and return
      end
    else
      render :text => "ERROR" and return
    end
  end

  protected

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

  def get_recipients
    get_alerts_recipient_api_endpoint = "#{Settings.api_endpoints.GetRecipientsEmailForNetworkAlerts}/#{current_user_id}"
    get_alerts_recipient_response = nil
    hydra = Typhoeus::Hydra.hydra
    get_alerts_recipient_request = Typhoeus::Request.new(get_alerts_recipient_api_endpoint)
    hydra.queue get_alerts_recipient_request
    get_alerts_recipient_request.on_complete do |response|
      get_alerts_recipient_response = response
    end
    hydra.run

    emails = nil
    if get_alerts_recipient_response.success? && !api_contains_error("GetRecipientsEmailForNetworkAlerts", get_alerts_recipient_response)
      api_response = JSON.parse(get_alerts_recipient_response.response_body)["GetRecipientsEmailForNetworkAlertsResult"]
      emails = api_response["recipientEmailDetails"] if api_response["error"] == nil
    end
    return emails
  end

  def get_all_industries
    @industries = []
    @sub_industries = []
    get_all_industry_list_api_endpoint = "#{Settings.api_endpoints.GetAllIndustryList}"
    response = Typhoeus.get(get_all_industry_list_api_endpoint)
    if response.success? && !api_contains_error("GetAllIndustryList", response)
      api_response = JSON.parse(response.response_body)["GetAllIndustryListResult"]
      industries_collection = api_response["industry"]
      @industries = industries_collection.collect { |industry| industry["industryType"] }
      @sub_industries = industries_collection.collect { |industry| industry["subIndustry"] }
    end
  end

  def get_all_locations
    @countries = []
    @states = []
    @areas = []
    get_all_location_list_api_endpoint = "#{Settings.api_endpoints.GetAllLocationList}"
    response = Typhoeus.get(get_all_location_list_api_endpoint)
    if response.success? && !api_contains_error("GetAllLocationList", response)
      api_response = JSON.parse(response.response_body)["GetAllLocationListResult"]
      @location_collection = api_response["locations"]
      #@countries = @location_collection.collect { |location|
      #  @states.push location["state"].collect { |state|
      #    @areas.push state["area"]
      #    state["stateName"]
      #  }
      #  location["country"]
      #}
    end
  end

end
