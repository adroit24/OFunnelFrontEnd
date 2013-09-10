module GroupsHelper

  def organizer_id(organizer)
    return "#{organizer["userId"]}"
  end

  def organizer_user_name(organizer)
    return "#{organizer["firstName"]} #{organizer["lastName"]}"
  end

  def organizer_headline(organizer)
    return "#{organizer["headline"]}"
  end

  def organizer_score(organizer)
    return "#{organizer["score"]}"
  end

  def organizer_profile_pic(organizer)
    profile_pic = "#{organizer["profilePicUrl"]}"
    return profile_pic.blank? ? "/assets/user_photo.jpg" : profile_pic
  end

  def organizer_profile_url(organizer)
    profile_url = "#{organizer["profileUrl"]}"
    return profile_url.nil? ? "#" : profile_url
  end

  def member_id(member)
    return "#{member["userId"]}"
  end

  def member_user_name(member)
    return "#{member["firstName"]} #{member["lastName"]}"
  end

  def member_headline(member)
    return "#{member["headline"]}"
  end

  def member_score(member)
    return "#{member["score"]}"
  end

  def member_profile_pic(member)
    profile_pic = "#{member["profilePicUrl"]}"
    return profile_pic.blank? ? "/assets/user_photo.jpg" : profile_pic
  end

  def member_profile_url(member)
    profile_url = "#{member["profileUrl"]}"
    return profile_url.nil? ? "#" : profile_url
  end

end
