class GoogleController < ApplicationController
  before_filter :check_current_user

  def authorize_with_google
    session[:google_token] = nil
    #Redirect your user in order to authenticate
    redirect_url = google_client.auth_code.authorize_url(
        :scope => Settings.google.SCOPE,
        :redirect_uri => Settings.google.REDIRECT_URI,
        :access_type => 'offline'
        #TODO: Remove in production
        #:approval_prompt => 'force'
    )
    logger.fatal "Redirect to google for first time: #{redirect_url}"
    redirect_to redirect_url
  end

  # This method will handle the callback once the user authorizes your application
  def google_authorization_callback
    begin
      #Fetch the 'code' query parameter from the callback
      code = params[:code]

      #Get token object, passing in the authorization code from the previous step
      logger.fatal "Redirect to google for getting token: #{code}  ,  #{Settings.google.REDIRECT_URI}"
      token = google_client.auth_code.get_token(code, {:redirect_uri => Settings.google.REDIRECT_URI})

      api_endpoint = "#{Settings.api_endpoints.Login}"
      response = Typhoeus.post(api_endpoint, body: {
          userId: current_user_id,
          loginType: 'GMAIL',
          accessToken: token.refresh_token
      })

      if response.success? && !api_contains_error("Login", response)
        add_access_token_api_response = JSON.parse(response.response_body)
        add_access_token_api_response = add_access_token_api_response["LoginResult"]
        if add_access_token_api_response["isUserLogedIn"] == true
          session[:google_token] = token.token
        end
      end

      redirect_to user_path(current_user_id)
    rescue OAuth2::Error => e
      logger.fatal e.message
      logger.fatal e.backtrace.inspect
      redirect_to Settings.google_auth_url
    end
  end

  protected

  def google_client
    OAuth2::Client.new(
        Settings.google.CLIENT_ID,
        Settings.google.CLIENT_SECRET,
        :authorize_url => "/o/oauth2/auth",
        :token_url => "/o/oauth2/token",
        :site => "https://accounts.google.com"
    )
  end
end
