module RequestsHelper

  def is_tab_active?(tab)
    session[:active_tab] == tab ? "active" : "inactive"
  end

  def request_partial
    session[:active_tab] == "sent" ? "made" : "got"
  end

  def Updated_time(timeStr)
    DateTime.strptime(timeStr, '%m/%d/%Y %H:%M:%S %p').to_date.strftime('%d/%m/%Y')
  end

  def request_class(request)
    status = request["status"]
    case status
      when "ACCEPTED"
        return "green"
      when "DECLINED"
        return "orange"
      when "IGNORED", "PENDING"
        return "grey"
      when "REQUESTEDINFO"
        return "blue"
    end
  end

  def comma_separator(index,length)
    return ',' unless index + 1 == length
  end

end
