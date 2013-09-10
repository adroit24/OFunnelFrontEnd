class UsersController < ApplicationController

  before_filter :check_current_user, :set_tab

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

  protected

  def set_tab
    session[:selected_tab] = "users"
    session[:active_tab] = ""
  end
end
