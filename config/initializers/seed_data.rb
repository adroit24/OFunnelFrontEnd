if false
  db = SQLite3::Database.new 'db/development.sqlite3'
  db.execute "DELETE FROM industries;"
  db.execute "DELETE FROM locations;"

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

  get_all_industry_list_api_endpoint = "#{Settings.api_endpoints.GetAllIndustryList}"
  response = Typhoeus.get(get_all_industry_list_api_endpoint)
  if response.success? && !api_contains_error("GetAllIndustryList", response)
    api_response = JSON.parse(response.response_body)["GetAllIndustryListResult"]
    industries = api_response["industry"]
    unless industries.blank?
      industries.each do |industry|
        Industry.create(
            :id =>  industry["industryId"].to_i,
            :name => industry["industryType"]
        )
      end
    end
  end

  get_all_location_list_api_endpoint = "#{Settings.api_endpoints.GetAllLocationList}"
  response = Typhoeus.get(get_all_location_list_api_endpoint)
  if response.success? && !api_contains_error("GetAllLocationList", response)
    api_response = JSON.parse(response.response_body)["GetAllLocationListResult"]
    locations = api_response["locations"]
    unless locations.blank?
      locations.each do |location|
        Location.create(
            :id =>  location["stateId"].to_i,
            :name => location["state"]
        )
      end
    end
  end
end
