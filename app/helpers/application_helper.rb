module ApplicationHelper

  def mobile_device()
    /android.+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.match(request.user_agent) || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|e\-|e\/|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(di|rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|xda(\-|2|g)|yas\-|your|zeto|zte\-/i.match(request.user_agent[0..3]) ? true : false
  end

  def is_tab_selected?(tab)
    session[:selected_tab] == tab ? "selected" : ""
  end

  def profile_pic_url
    profile_pic = current_user_profile[:profilePictureUrl]
    return profile_pic.blank? ? "/assets/user_photo.jpg" : "#{profile_pic}"
  end

  def user_name
    return current_user_profile.nil? ? "" : "#{current_user_profile[:firstName]} #{current_user_profile[:lastName]}"
  end

  def user_first_name
    return current_user_profile.nil? ? "" : "#{current_user_profile[:firstName]}"
  end

  def user_last_name
    return current_user_profile.nil? ? "" : "#{current_user_profile[:lastName]}"
  end

  def user_email
    return current_user_profile.nil? ? "" : "#{current_user_profile[:email]}"
  end

  def company_name
    return current_user_profile.nil? ? "" : "#{current_user_profile[:companyName]}"
  end

  def job_title
    return current_user_profile.nil? ? "" : "#{current_user_profile[:position]}"
  end

  def location
    return current_user_profile.nil? ? "" : "#{current_user_profile[:location]["name"]}"
  end

  def skills
    skills = ""
    unless current_user_profile.nil?
      skill_collection = current_user_profile[:skills]
      unless skill_collection.nil?
        skill_set = []
        skill_collection["values"].each do |skill_element|
          skill_set << skill_element["skill"]["name"]
        end
        skills = skill_set.join(', ')
      end
    end
    return skills
  end

  def request_id(request)
    id = request["requestId"]
    return id
  end

  def get_request_visibility(request)
    visibility = request["visibility"]
    return visibility
  end

  def get_visibility_tags(request)
    visibility_tags = request["RequestVisibilityTags"]
    return visibility_tags.to_json
  end

  def request_point(request)
    point = "5"
    return point
  end

  def request_outcome(request)
    status = request_status(request)
    return status
  end

  def request_status(request)
    status = request["status"]
    case status
      when "ACCEPTED"
        return "Accepted"
      when "PENDING"
        return "Pending"
      when "DECLINED"
        return "Declined"
      when "IGNORED"
        return "Ignored"
      when "REQUESTEDINFO"
        return "Requested More Info"
    end
  end

  def request_message(request)
    return request["content"]
  end

  def request_query(request)
    return request["querySearched"]
  end

  def for_user_name(request)
    return request["forUserName"]
  end

  def from_user_name(request)
    return request["fromUserName"]
  end

  def to_user_name(request)
    return request["toUserName"]
  end

  def for_user_id(request)
    return request["forUserId"].to_i
  end

  def from_user_id(request)
    return request["fromUserId"].to_i
  end

  def to_user_id(request)
    return request["toUserId"].to_i
  end

  def for_user_profile_url(request)
    profile_url = request["forUserProfileUrl"]
    return profile_url.blank? ? "#" : "#{profile_url}"
  end

  def from_user_profile_url(request)
    profile_url = request["fromUserProfileUrl"]
    return profile_url.blank? ? "#" : "#{profile_url}"
  end

  def to_user_profile_url(request)
    profile_url = request["toUserProfileUrl"]
    return profile_url.blank? ? "#" : "#{profile_url}"
  end

  def for_user_profile_pic(request)
    profile_pic = request["forUserProfilePicUrl"]
    return profile_pic.blank? ? "/assets/user_photo.jpg" : "#{profile_pic}"
  end

  def from_user_profile_pic(request)
    profile_pic = request["fromUserProfilePicUrl"]
    return profile_pic.blank? ? "/assets/user_photo.jpg" : "#{profile_pic}"
  end

  def to_user_profile_pic(request)
    profile_pic = request["toUserProfilePicUrl"]
    return profile_pic.blank? ? "/assets/user_photo.jpg" : "#{profile_pic}"
  end

  def for_user_company(request)
    company = request["forUserCompany"]
    return company == "false" ? "" : company
  end

  def from_user_company(request)
    company = request["fromUserCompany"]
    return company == "false" ? "" : company
  end

  def to_user_company(request)
    company = request["toUserCompany"]
    return company == "false" ? "" : company
  end

  def for_user_headline(request)
    headline = request["forUserHeadline"]
    return headline == "--" ? "" : headline
  end

  def from_user_headline(request)
    headline = request["fromUserHeadline"]
    return headline == "--" ? "" : headline
  end

  def to_user_headline(request)
    headline = request["toUserHeadline"]
    return headline == "--" ? "" : headline
  end

  def for_user_linkedin_id(request)
    headline = request["forUserLinkedInId"]
    return headline == "--" ? "" : headline
  end

  def from_user_linkedin_id(request)
    headline = request["fromUserLinkedInId"]
    return headline == "--" ? "" : headline
  end

  def to_user_linkedin_id(request)
    headline = request["toUserLinkedInId"]
    return headline == "--" ? "" : headline
  end

  def for_user_score(request)
    return request["forUserScore"]
  end

  def from_user_score(request)
    return request["fromUserScore"]
  end

  def to_user_score(request)
    return request["toUserScore"]
  end

  def is_for_user_score_exists(request)
    return request["forUserScore"].to_i > 0 ? true : false
  end

  def is_from_user_score_exists(request)
    return request["fromUserScore"].to_i > 0 ? true : false
  end

  def is_to_user_score_exists(request)
    return request["toUserScore"].to_i > 0 ? true : false
  end

  def is_open_request(request)
    return (request["toUserId"].to_i == -1 and request["forUserId"].to_i == -1) ? true : false
  end

  def is_for_user_exists(request)
    return (request["forUserId"].to_i == -1) ? false : true
  end

  def is_to_user_exists(request)
    return (request["toUserId"].to_i == -1) ? false : true
  end

  def forUserAccountType(request)
    request["forUserAccountType"]
  end

  def user_account_id(connection)
    connection["accountId"]
  end

  def user_profile_pic_url(connection)
    profile_pic = connection["profilePicUrl"]
    return profile_pic.blank? ? "/assets/user_photo.jpg" : "#{profile_pic}"
  end

  def user_connection_strength(connection)
    connection["connectionStrength"]
  end

  # Google related helper methods

  def google_email(connection)
    email_array = connection["gd$email"]
    unless email_array.nil? or email_array.blank?
      return email_array[0]["address"]
    end
  end

  def google_username(connection)
    title = connection["title"]
    return title.nil? ? "" : title["$t"]
  end

  def forUserGoogleAccountId(request)
    request["forUserAccountId"]
  end

  # Facebook related helper methods

  def connection_facebook_id(connection)
    return connection["id"]
  end

  def connection_facebook_name(connection)
    return connection["name"]
  end

  def connection_facebook_profile_url(connection)
    profile_url = connection["link"]
    return profile_url.blank? ? "#" : profile_url
  end

  def connection_facebook_profile_pic_url(connection)
    picture_hash = connection["picture"]
    unless picture_hash.nil?
      profile_pic_url = picture_hash["data"].blank? ? "/assets/user_photo.jpg" : picture_hash["data"]["url"]
    else
      profile_pic_url = "/assets/user_photo.jpg"
    end
    return profile_pic_url.blank? ? "/assets/user_photo.jpg" : "#{profile_pic_url}"
  end

  def connection_facebook_headline(connection)
    work_hash = connection["work"]
    unless work_hash.nil?
      work_hash = work_hash[0]
      company = work_hash["employer"].blank? ? "" : work_hash["employer"]["name"]
      position = work_hash["position"].blank? ? "" : work_hash["position"]["name"]
      if position.blank?
        headline = "#{company}"
      elsif company.blank?
        headline = "#{position}"
      else
        headline = "#{position}, #{company}"
      end
    else
      headline = ""
    end
    return headline
  end

  def connection_facebook_company(connection)
    work_hash = connection["work"]
    unless work_hash.nil?
      work_hash = work_hash[0]
      company = work_hash["employer"].blank? ? "" : work_hash["employer"]["name"]
      return company.blank? ? "" : company
    else
      return ""
    end
  end

  def connection_facebook_position(connection)
    work_hash = connection["work"]
    unless work_hash.nil?
      work_hash = work_hash[0]
      position = work_hash["position"].blank? ? "" : work_hash["position"]["name"]
      return position.blank? ? "" : position
    else
      return ""
    end
  end

  def forUserFacebookHeadline(request)
    request["forUserCompany"]
  end
end
