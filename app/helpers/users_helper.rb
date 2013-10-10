module UsersHelper

  def profile_user_name
    return "#{@profile["firstName"]} #{@profile["lastName"]}"
  end

  def profile_user_first_name
    return "#{@profile["firstName"]}"
  end

  def profile_user_company
    return @profile["company"]
  end

  def profile_user_email
    return @profile["email"]
  end

  def profile_user_location
    return @profile["location"]
  end

  def profile_user_profile_pic_url
    profile_pic = @profile["profilePicUrl"]
    return profile_pic.blank? ? "/assets/user_photo.jpg" : "#{profile_pic}"
  end

  def profile_user_linkedin_profile_url
    return @profile["profileUrl"]
  end

  def profile_user_tags
    return @profile["userTags"]
  end

  def profile_tag_name(tag)
    return tag["tagName"]
  end

  def profile_tag_logo(tag)
    tag_logo =  tag["tagLogoUrl"]
    return tag["tagLogoUrl"].blank? ? "/assets/grouplogo.jpg" : "#{tag_logo}"
  end

  def profile_tag_id(tag)
    return tag["tagId"]
  end

  def profile_user_tag_id(tag)
    return tag["userTagId"]
  end

  def profile_is_approved_tag(tag)
    return tag["isApprovedTag"]
  end

  def profile_is_pending_tag(tag)
    return tag["isTagJoinRequestPending"]
  end

  def profile_request_details
    return @profile["requestDetails"]
  end

  def show_bottom_border(offset,tags)
    return ((offset + 1) == tags.length || (offset + 1) == tags.length) ? false : true
  end

  # Alerts helper

  def friend_profile_pic_url(user)
    profile_pic = user["yourConnectionProfilePicUrl"]
    return profile_pic.blank? ? "/assets/user_photo.jpg" : "#{profile_pic}"
  end

  def f_connected_profile_pic_url(user)
    profile_pic = user["connectedToProfilePicUrl"]
    return profile_pic.blank? ? "/assets/user_photo.jpg" : "#{profile_pic}"
  end

  def friend_profile_url(user)
    profile_pic = user["yourConnectionProfileUrl"]
    return profile_pic.blank? ? "#" : "#{profile_pic}"
  end

  def f_connected_profile_url(user)
    profile_pic = user["connectedToProfileUrl"]
    return profile_pic.blank? ? "#" : "#{profile_pic}"
  end

  def friend_name(user)
    return "#{user['yourConnectionFirstName']} #{user['yourConnectionLastName']}"

  end

  def f_connected_name(user)
    return "#{user['connectedToFirstName']} #{user['connectedToLastName']}"
  end

  def friend_headline(user)
    return user['yourConnectionHeadline']

  end

  def f_connected_headline(user)
    return user['connectedToHeadline']
  end

  def f_connected_to_salesforce(user)
    return user['isConnectionAddedInSalesForce']
  end

end
