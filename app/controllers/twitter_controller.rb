class TwitterController < ApplicationController

  before_filter :initialize_twitter_client

  def index
    authorize_with_twitter
  end

  def login_with_twitter
  end

  def authorize_with_twitter
    request_token = session['twitter_client'].request_token(:oauth_callback => Settings.twitter.REDIRECT_URI)
    session[:temp_twitter_token] = request_token.token
    session[:temp_twitter_secret] = request_token.secret
    redirect_to request_token.authorize_url
  end

  # This method will handle the callback once the user authorizes your application
  def twitter_authorization_callback
    access_token = session['twitter_client'].authorize(
        session[:temp_twitter_token],
        session[:temp_twitter_secret],
        :oauth_verifier => params[:oauth_verifier]
    )

    session[:temp_twitter_token] = nil
    session[:temp_twitter_secret] = nil
    if session['twitter_client'].authorized?
      session[:twitter_access_token] = access_token.token
      session[:twitter_secret_token] = access_token.secret

      profile = session['twitter_client'].info
      user_data = {
          :userId => current_user_id,
          :twitterId => profile["id"],
          :accessToken => access_token.token,
          :tokenSecret => access_token.secret,
          :profileUrl => "https://twitter.com/#{profile["screen_name"]}",
          :profilePictureUrl => profile["profile_image_url"]
      }
      api_endpoint = "#{Settings.api_endpoints.AddTweeterDetails}"
      add_twitter_response = Typhoeus.post(api_endpoint, body: user_data)
      unless add_twitter_response.success?
        log_errors(add_twitter_response.return_message)
      end
      session[:twitter_client] = nil
      render :text => "accessToken: #{access_token.token} tokenSecret: #{access_token.secret}"
    else
      redirect :action => login_with_twitter
    end
    session[:twitter_client] = nil
  end

  def show
    linkedin_id = URI.escape(params[:id])
    api_endpoint = "#{Settings.api_endpoints.GetTweetsFromTwitter}/#{linkedin_id}"
    response = Typhoeus.get(api_endpoint)

    if response.success?
      api_response = JSON.parse(response.response_body)
      twitter_data = api_response["GetTweetsFromTwitterResult"]
      if twitter_data["personFound"]
        @tweets = twitter_data["tweetdata"]
      else
        redirect_to :action => 'search'
      end
    else
      log_errors(response.return_message)
    end
  end

  protected

  def initialize_twitter_client
    session[:twitter_client] = session[:twitter_client] || TwitterOAuth::Client.new(
        :consumer_key => Settings.twitter.CONSUMER_KEY,
        :consumer_secret => Settings.twitter.CONSUMER_SECRET
    )
  end
end
