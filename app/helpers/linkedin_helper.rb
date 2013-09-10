module LinkedinHelper

  def connection_user_name(person)
    return "#{person["first-name"]} #{person["last-name"]}"
  end

  def connection_company_name(person)
    positions = person["positions"]
    unless (positions.nil? or positions.length < 1 or positions["position"].nil? or positions["position"][0].nil? or positions["position"][0]["company"].nil?)
      return "#{positions["position"][0]["company"]["name"]}"
    end
  end

  def connection_job_title(person)
    positions = person["positions"]
    unless positions.nil? or positions["position"].nil? or positions["position"][0].nil?
      return positions.length > 0 ? "#{positions["position"][0]["title"]}" : ""
    end
  end

  def connection_location(person)
    return "#{person["location"]["name"]}"
  end

  def connection_skills(person)
    skill_collection = person[:skills]
    unless skill_collection.nil?
      skill_set = []
      skill_collection["values"].each do |skill_element|
        skill_set << skill_element["skill"]["name"]
      end
      return skill_set.join(', ')
    else
      return ""
    end
  end

  def connection_profile_url(person)
    profile_url = "#{person["public-profile-url"]}"
    return profile_url.blank? ? "#" : profile_url
  end

  def connection_profile_pic(person)
    pic_url = "#{person["picture-url"]}"
    return pic_url.blank? ? "/assets/user_photo.jpg" : pic_url
  end

  def linkedin_id(connection)
    return connection["id"]
  end

  def linkedin_connection_name(connection)
    return "#{connection["firstName"]} #{connection["lastName"]}"
  end

  def linkedin_headline(connection)
    return connection["headline"]
  end

  def linkedin_profile_pic(connection)
    profile_pic = "#{connection["pictureUrl"]}"
    return profile_pic.blank? ? "/assets/user_photo.jpg" : profile_pic
  end

  def linkedin_profile_url(connection)
    profile_url = "#{connection["publicProfileUrl"]}"
    return profile_url.nil ? "#" : profile_url
  end

  def linkedin_company_name(connection)
    positions = connection["positions"]
    unless (positions.nil? or positions["_total"].to_i < 1)
      company = positions["values"][0]["company"]["name"]
      unless company.nil?
        return company
      else
        return ""
      end
    end
  end

  def linkedin_job_name(connection)
    positions = connection["positions"]
    unless (positions.nil? or positions["_total"].to_i < 1)
      if positions.length > 0
        job = positions["values"][0]["title"]
        unless job.nil?
          job = job
        else
          job = ""
        end
      else
        job = ""
      end
      return job
    end
  end

  def windowed_page_numbers(current_page,total_pages)
    left = nil
    middle = nil
    right = nil
    case current_page
      when 1
        left = [1,2,3]
        right = [total_pages]
      when 2
        left = [1,2,3]
        right = [total_pages]
      when total_pages - 1
        left = [1]
        right = ((total_pages - 2)..total_pages).to_a
      when total_pages
        left = [1]
        right = ((total_pages - 2)..total_pages).to_a
      else
        left = [1]
        middle = ((current_page - 1)..current_page + 1).to_a
        right = [total_pages]
    end
    return left, middle, right
  end

  def dr_pg_link_class(current_page,link_number)
    return (current_page == link_number) ? "pl-inactive2" : "pl-active2"
  end

  def dr_pg_link_class2(current_page,link_number)
    return (current_page == link_number) ? "pl-inactive3" : "pl-active3"
  end

end
