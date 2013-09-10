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

end
