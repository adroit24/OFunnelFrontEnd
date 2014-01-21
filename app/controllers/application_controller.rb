class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :require_ssl?, :user_tags, :initialize_ofunnel
  helper_method :check_current_user, :current_user, :current_user_id, :current_user_id_from_cookies, :current_user_profile, :current_user_score, :show_ofunnel_help, :check_google_session, :check_facebook_session, :to_dc, :create_default_hootsuite_session, :create_default_salesforce_session
  rescue_from Exception, :with => :server_error if Rails.env.production?

  def server_error(exception)
    ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver
    redirect_to root_url and return
  end

  def current_user
    return session[:linkedin_id]
  end

  def set_current_user(linkedin_id)
    session[:linkedin_id] = linkedin_id
  end

  def current_user_id
    if params[:controller] == "hootsuite"
      return session[:user_id] || current_user_id_from_cookies
    else
      return session[:user_id]
    end
  end

  def current_user_id_from_cookies
    return cookies.signed[:user_id]
  end

  def set_current_user_id(user_id)
    session[:user_id] = user_id
    cookies.permanent.signed[:user_id] = {:value => user_id, :domain => :all}
  end

  def current_user_profile
    return session[:profile]
  end

  def set_current_user_profile(profile)
    session[:profile] = profile
  end

  def current_user_score
    return session[:user_score]
  end

  def set_current_user_score(score)
    session[:user_score] = score
  end

  def set_show_ofunnel_help(flag)
    session[:show_help] = flag
  end

  def current_user_name
    return current_user_profile.nil? ? "" : "#{current_user_profile[:firstName]} #{current_user_profile[:lastName]}"
  end

  # Commented due to bug#324
  #def show_ofunnel_help
  #  return session[:show_help]
  #end

  def user_tags
    if current_user
      if session[:user_tags].nil?
        get_tags_api_endpoint = "#{Settings.api_endpoints.GetUserTagsFromUserId}/#{current_user_id}"
        get_tags_response = nil

        hydra = Typhoeus::Hydra.hydra
        get_tags_request = Typhoeus::Request.new(get_tags_api_endpoint)
        hydra.queue get_tags_request
        get_tags_request.on_complete do |response|
          get_tags_response = response
        end
        hydra.run
        if get_tags_response.success? && !api_contains_error("GetUserTagsFromUserId", get_tags_response)
          tags = JSON.parse(get_tags_response.response_body)["GetUserTagsFromUserIdResult"]
          unless tags.nil?
            session[:user_tags] = tags["userTagsDetails"]
            @user_tags = session[:user_tags]
          else
            @user_tags = nil
          end
        else
          @user_tags = nil
        end
      else
        @user_tags = session[:user_tags]
      end
    end
  end

  def log_errors(error)
    api_endpoint = "#{Settings.api_endpoints.Addlogs}"
    response = Typhoeus.post(api_endpoint, body: { logInfo: error})
    if response.success?
      logger.error error
      return true
    else
      logger.error "Cannot log to Backend server"
      return false
    end
  end

  def check_current_user
    if session[:linkedin_id].nil?
      session[:return_to] = current_url
      cookies.permanent.signed[:return_to] = {:value => current_url, :domain => :all}
      redirect_to Settings.linkedin_auth_url, :protocol => 'http' and return
    else
      return true
    end
  end

  def check_google_session
    session[:google_token].nil? ? false : true
  end

  def check_facebook_session
    session[:facebook_token].nil? ? false : true
  end

  def check_salesforce_session
    if session[:salesforce_token].nil?
      session[:return_to] = current_url
      redirect_to Settings.salesforce_auth_url, :protocol => 'http' and return
    else
      return true
    end
  end

  def check_hootsuite_session
    unless session[:hootsuite].nil?
      session[:return_to] = current_url
      redirect_to hootsuite_session_init_url
    else
      return true
    end
  end

  def initialize_ofunnel
    session[:selected_connections] = session[:selected_connections].nil? ? {} : session[:selected_connections]
  end

  def clear_session
    set_current_user(nil)
    set_current_user_id(nil)
    set_current_user_score(nil)
    set_current_user_profile(nil)
  end

  def create_default_hootsuite_session
    theme = params[:theme].blank? ? "blue_steel" : params[:theme]
    tab = cookies.signed[:tab].nil? ? "TARGETS" : cookies.signed[:tab]
    cookies.permanent.signed[:user_id] = {:value => nil, :domain => :all}
    cookies.permanent.signed[:h_user_id] = {:value => nil, :domain => :all}
    cookies.permanent.signed[:authenticated] = {:value => false, :domain => :all}
    cookies.permanent.signed[:connected] = {:value => false, :domain => :all}
    cookies.permanent.signed[:theme]= {:value => theme, :domain => :all}
    cookies.permanent.signed[:userName] = {:value => "OFunnel", :domain => :all}
    cookies.permanent.signed[:query] = {:value => request.query_string, :domain => :all}
    cookies.permanent.signed[:tab] = {:value => tab, :domain => :all}
    cookies.permanent.signed[:offset] = {:value => 0, :domain => :all}
    cookies.permanent.signed[:target_offset] = {:value => 0, :domain => :all}
  end

  def create_default_salesforce_session
    cookies.permanent.signed[:user_id] = {:value => nil, :domain => :all}
    cookies.permanent.signed[:sf_authenticated] = {:value => false, :domain => :all}
  end

  def api_contains_error(api_name, api_response)
    begin
      api_name = api_name + "Result"
      api_response_body = JSON.parse(api_response.response_body)
      if api_response_body[api_name].blank?
        true
      elsif api_response_body[api_name]["error"].blank?
        false
      else
        log_errors(api_response_body[api_name]["error"])
        logger.error api_response_body[api_name]["error"]
        true
      end
    rescue Exception => e
      logger.error e
      return true
    end
  end

  def current_url
    return "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
  end

  def mobile_device()
    /android.+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.match(request.user_agent) || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|e\-|e\/|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(di|rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|xda(\-|2|g)|yas\-|your|zeto|zte\-/i.match(request.user_agent[0..3]) ? true : false
  end

  def to_dc(str)
    return str.downcase.capitalize unless str.blank?
    return ""
  end

  private

  SECURE_ACTIONS = {
      :braintree => ["upgrade", "create_subscription", "discounted_price_using_promo_code"],
      :hootsuite => ["index", "authorize", "authorize_callback", "stream", "targets", "add_relationships", "remove_relationship", "get_linkedin_profile", "disconnect"],
      :users => ["win8_authentication"]
  }

  # Called as a before_filter in controllers that have some https:// actions
  def require_ssl?
    if !request.ssl? and secure_action?
      redirect_to :protocol => 'https://', :host => Settings.https.host,:port=> Settings.https.port
      # we don't want to continue with the action, so return false from the filter
      return false
    elsif request.ssl? and !secure_action?
      redirect_to :protocol => 'http://', :host => Settings.http.host,:port=> Settings.http.port
    end
  end

  def secure_action?
    status = false
    SECURE_ACTIONS.each do |secure_controller,secure_action|
      status = (controller_name.eql? secure_controller.to_s and secure_action.include? action_name) ? true : false
      break if status
    end
    return status
  end

end
