class FacebookController < ApplicationController
  before_filter :check_current_user

  def authorize_with_facebook
    session[:facebook_token] = nil
    #Redirect your user in order to authenticate
    redirect_url = facebook_client.auth_code.authorize_url(
        :scope => Settings.facebook.SCOPE,
        :redirect_uri => Settings.facebook.REDIRECT_URI
    )
    logger.fatal "Redirect to facebook for first time: #{redirect_url}"
    redirect_to redirect_url
  end

  # This method will handle the callback once the user authorizes your application
  def facebook_authorization_callback
    begin
      #Fetch the 'code' query parameter from the callback
      code = params[:code]

      #Get token object, passing in the authorization code from the previous step
      logger.fatal "Redirect to facebook for getting token: #{code}  ,  #{Settings.facebook.REDIRECT_URI}"
      token = facebook_client.auth_code.get_token(code, {:redirect_uri => Settings.facebook.REDIRECT_URI, :parse => :facebook})

      api_endpoint = "#{Settings.api_endpoints.Login}"
      response = Typhoeus.post(api_endpoint, body: {
          userId: current_user_id,
          loginType: 'FACEBOOK',
          accessToken: token.token
      })

      if response.success? && !api_contains_error("Login", response)
        add_access_token_api_response = JSON.parse(response.response_body)
        add_access_token_api_response = add_access_token_api_response["LoginResult"]
        if add_access_token_api_response["isUserLogedIn"] == true
          session[:facebook_token] = token.token
        end
      end

      redirect_to user_path(current_user_id)
    rescue OAuth2::Error => e
      logger.fatal e.message
      logger.fatal e.backtrace.inspect
      redirect_to Settings.facebook_auth_url
    end
  end

  protected

  def facebook_client
    OAuth2::Client.new(
        Settings.facebook.APP_ID,
        Settings.facebook.APP_SECRET,
        :authorize_url => "https://www.facebook.com/dialog/oauth",
        :token_url => "https://graph.facebook.com/oauth/access_token",
        :site => "https://graph.facebook.com"
    )
  end
end
