class AlertsController < ApplicationController
  layout "relationships"
  before_filter :check_current_user

  def index
    #if mobile_device
    #  @count = 999999
    #else
    @count = 25
    #end
    @offset = params[:offset].nil? ? 0 : params[:offset].to_i
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

    if mobile_device
      render "responsive_discover_relationships", :layout => "responsive_relationships" and return
    end
  end

  def new
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
    industries =  { "error" => true }
    unless params[:query].blank?
      api_endpoint = "#{Settings.api_endpoints.GetIndustryList}/#{current_user_id}/#{params[:query]}"
      response = Typhoeus.get(api_endpoint)
      if response.success? && !api_contains_error("GetIndustryList", response)
        industries = JSON.parse(response.response_body)["GetIndustryListResult"]
      end
    end
    render :json => industries.to_json and return
  end

  def locations
    locations= { "error" => true }
    unless params[:query].blank?
      api_endpoint = "#{Settings.api_endpoints.GetLocationList}/#{current_user_id}/#{params[:query]}"
      response = Typhoeus.get(api_endpoint)
      if response.success? && !api_contains_error("GetLocationList", response)
        locations = JSON.parse(response.response_body)["GetLocationListResult"]
      end
    end
    render :json => locations.to_json and return
  end

end
