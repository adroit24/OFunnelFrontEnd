class GroupsController < ApplicationController
  before_filter :check_current_user, :set_tab

  require 'net/http/post/multipart' # multipart-post gem
  require 'mime/types' #mime-types gem
  require 'net/http'
  require 'csv'

  def index

  end

  def show
    group_id = params[:id]
    @tag_id = group_id

    get_organizer_and_request_api_endpoint = "#{Settings.api_endpoints.GetOrganizerAndRequestsDetailsInGroup}/#{group_id}"
    get_members_in_group_api_endpoint = "#{Settings.api_endpoints.GetMembersInGroup}/#{group_id}"
    get_organizer_and_request_response = nil
    get_members_in_group_response = nil

    hydra = Typhoeus::Hydra.hydra
    get_organizer_and_request = Typhoeus::Request.new(get_organizer_and_request_api_endpoint)
    get_members_in_group_request = Typhoeus::Request.new(get_members_in_group_api_endpoint)
    hydra.queue get_organizer_and_request
    hydra.queue get_members_in_group_request
    get_organizer_and_request.on_complete do |response|
      get_organizer_and_request_response = response
    end
    get_members_in_group_request.on_complete do |response|
      get_members_in_group_response = response
    end

    hydra.run
    if get_organizer_and_request_response.success? && !api_contains_error("GetOrganizerAndRequestsDetailsInGroup", get_organizer_and_request_response)
      get_organizer_and_request_api_response = JSON.parse(get_organizer_and_request_response.response_body)["GetOrganizerAndRequestsDetailsInGroupResult"]
      @tag_name = get_organizer_and_request_api_response["tagName"]
      @tag_description = get_organizer_and_request_api_response["description"].blank? ? "No description added" : get_organizer_and_request_api_response["description"]
      @tag_logo = get_organizer_and_request_api_response["tagLogoUrl"].blank? ? "/assets/grouplogo.jpg" : get_organizer_and_request_api_response["tagLogoUrl"]
      @organizers = get_organizer_and_request_api_response["organizers"]
      @member_count = get_organizer_and_request_api_response["noOfMember"]
      @request_count = get_organizer_and_request_api_response["noOfRequests"]
      @requests = get_organizer_and_request_api_response["requestDetails"]
      @organizers_array = @organizers.nil? ? [] : @organizers.collect {|oraganizer| oraganizer["userId"] }
    else
      @tag_name, @tag_description, @tag_logo, @member_count, @request_count, @requests, @organizers = nil
    end
    if get_members_in_group_response.success? && !api_contains_error("GetMembersInGroup", get_members_in_group_response)
      get_members_in_group_api_response = JSON.parse(get_members_in_group_response.response_body)["GetMembersInGroupResult"]
      @group_members = get_members_in_group_api_response["groupUser"]
      @members_array = @group_members.nil? ? [] : @group_members.collect {|member| member["userId"] }
    else
      @group_members = nil
    end
  end

  def members
    group_id = params[:id]

    get_organizer_and_request_api_endpoint = "#{Settings.api_endpoints.GetOrganizersAndMembersInGroup}/#{group_id}"
    get_members_in_group_api_endpoint = "#{Settings.api_endpoints.GetMembersInGroup}/#{group_id}"
    get_organizer_and_request_response = nil
    get_members_in_group_response = nil

    hydra = Typhoeus::Hydra.hydra
    get_organizer_and_request = Typhoeus::Request.new(get_organizer_and_request_api_endpoint)
    get_members_in_group_request = Typhoeus::Request.new(get_members_in_group_api_endpoint)
    hydra.queue get_organizer_and_request
    hydra.queue get_members_in_group_request
    get_organizer_and_request.on_complete do |response|
      get_organizer_and_request_response = response
    end
    get_members_in_group_request.on_complete do |response|
      get_members_in_group_response = response
    end

    hydra.run

    if get_organizer_and_request_response.success? && !api_contains_error("GetOrganizersAndMembersInGroup", get_organizer_and_request_response)
      get_organizer_and_request_api_response = JSON.parse(get_organizer_and_request_response.response_body)["GetOrganizersAndMembersInGroupResult"]
      @tag_name = get_organizer_and_request_api_response["tagName"]
      @tag_id = group_id
      @tag_description = get_organizer_and_request_api_response["description"].blank? ? "No description added" : get_organizer_and_request_api_response["description"]
      @tag_logo = get_organizer_and_request_api_response["tagLogoUrl"].blank? ? "/assets/grouplogo.jpg" : get_organizer_and_request_api_response["tagLogoUrl"]
      @organizers = get_organizer_and_request_api_response["organizers"]
      @member_count = get_organizer_and_request_api_response["memberCount"]
      @request_count = get_organizer_and_request_api_response["noOfRequests"]
      @requests = get_organizer_and_request_api_response["requestDetails"]
      @members = get_organizer_and_request_api_response["groupUser"]
      @organizers_array = @organizers.nil? ? [] : @organizers.collect {|oraganizer| oraganizer["userId"] }
    else
      @tag_name, @tag_id, @tag_description, @tag_logo, @member_count, @request_count, @requests, @organizers = nil
    end
    if get_members_in_group_response.success? && !api_contains_error("GetMembersInGroup", get_members_in_group_response)
      get_members_in_group_api_response = JSON.parse(get_members_in_group_response.response_body)["GetMembersInGroupResult"]
      @group_members = get_members_in_group_api_response["groupUser"]
    else
      @group_members = nil
    end
  end

  def add
    group_name = params["group-name"]
    group_admin = params["group-admin"]
    description = params["description-message"]
    group_logo = params["group_logo"]
    api_endpoint = "#{Settings.api_endpoints.AddTag}"

    response = Typhoeus.post(api_endpoint,
                             :body => {
                                 :userId => current_user_id,
                                 :tagName=> group_name,
                                 :description => description,
                                 :groupLogo =>  (group_logo.nil? ? nil : Base64.encode64(group_logo.tempfile.read))
                             })
    if response.success? && !api_contains_error("AddTag", response)
      api_response = JSON.parse(response.response_body)["AddTagResult"]
      @tag_name = api_response["tagName"]
      @tag_id = api_response["tagId"]
      @user_tag_id = api_response["userTagId"]
    else
      @tag_name, @tag_id, @user_tag_id = nil
      log_errors(response.return_message)
    end
    redirect_to user_path(current_user_id)
    #render :json => {:tagName => @tag_name, :tagId => @tag_id,:userTagId => @user_tag_id }
  end

  def delete
    user_tag_id = params[:id]
    api_endpoint = "#{Settings.api_endpoints.DeleteTag}"
    response = Typhoeus.post(api_endpoint, body: { userTagId: user_tag_id})
    is_deleted = nil
    if response.success? && !api_contains_error("DeleteTag", response)
      api_response = JSON.parse(response.response_body)["DeleteTagResult"]
      is_deleted = api_response["status"]
    end
    is_deleted = is_deleted.nil? ? false : true
    render :json => {:isDeleted => is_deleted}
  end

  def add_member
    names =params[:names]
    emails =params[:emails]
    tag_id =params[:tag_id]

    api_response = nil
    unless (names.blank? or emails.blank? or tag_id.blank?)
      emails.each_with_index do |email,i|
        name = names[i]
        name_array = name.split
        name_length = name_array.length
        if name_length > 1
          first_name = name_array[0..(name_length-2)].join(" ")
          last_name = name_array[(name_length-1)]
        else
          first_name = name
          last_name = ""
        end
        api_endpoint = "#{Settings.api_endpoints.InviteMemberToGroupV1}"
        response = Typhoeus.post(api_endpoint, body: {
            adminUserId: current_user_id,
            invitedUserEmail: email,
            tagId: tag_id,
            invitedUserFirstName: first_name,
            invitedUserLastNameName: last_name
        })
        if response.success? && !api_contains_error("InviteMemberToGroupV1", response)
          api_response = JSON.parse(response.response_body)["InviteMemberToGroupV1Result"]
        else
          api_response = {"error" => true}
        end
      end
    else
      redirect_to root_path and return
    end

    if request.xhr?
      render :json => api_response.to_json
    else
      redirect_to group_path(tag_id)
    end
  end

  def add_admin
    user_id = params[:user_id]
    tag_id = params[:tag_id]
    api_endpoint = "#{Settings.api_endpoints.AddOrganizerToGroup}"
    response = Typhoeus.post(api_endpoint, body: {
        userId: user_id,
        tagId: tag_id
    })
    #if response.success? && !api_contains_error("AddOrganizerToGroup", response)
    #  api_response = JSON.parse(response.response_body)["AddOrganizerToGroupResult"]
    redirect_to group_path(tag_id)
    #end
  end

  def join
    invite_id = params[:invite_id]
    token = params[:token]
    api_endpoint = "#{Settings.api_endpoints.AddMemberToGroup}"
    response = Typhoeus.post(api_endpoint, body: {
        userId: current_user_id,
        inviteId: invite_id,
        inviteToken: token,
        isOrzanizer: false
    })

    if response.success? && !api_contains_error("AddMemberToGroup", response)
      api_response = JSON.parse(response.response_body)["AddMemberToGroupResult"]
      if api_response["isValidToken"] == true
        group_id = api_response["tagId"]
        redirect_to group_path(group_id)
      else
        redirect_to user_path(current_user_id)
      end
    else
      redirect_to user_path(current_user_id)
    end
  end

  def join_login_bypass
    tag_id = params[:tag_id]
    api_endpoint = "#{Settings.api_endpoints.AddInvitedMemberToGroup}"
    response = Typhoeus.post(api_endpoint, body: {
        userId: current_user_id,
        tagId: tag_id
    })

    if response.success? && !api_contains_error("AddInvitedMemberToGroup", response)
      api_response = JSON.parse(response.response_body)["AddInvitedMemberToGroupResult"]
      if (api_response["isAlreadyMemberInTag"] == true or api_response["isMemberAddedInTag"] == true)
        group_id = api_response["tagId"]
        redirect_to group_path(group_id)
      else
        redirect_to user_path(current_user_id)
      end
    else
      redirect_to user_path(current_user_id)
    end
  end

  def group_request
    group_id = params["group-id"]
    api_endpoint = "#{Settings.api_endpoints.RequestToJoinGroup}"
    response = Typhoeus.post(api_endpoint, body: {
        userId: current_user_id,
        tagId: group_id
    })
    #if response.success? && !api_contains_error("RequestToJoinGroup", response)
    #  api_response = JSON.parse(response.response_body)["RequestToJoinGroupResult"]
    redirect_to group_path(group_id)
    #end
  end

  def approve_membership
    token = params["token"]
    invite_id = params["invite_id"]
    status = params["status"]
    api_endpoint = "#{Settings.api_endpoints.UpdateStatusForMembershipRequestToGroup}"
    response = Typhoeus.post(api_endpoint, body: {
        userId: current_user_id,
        inviteId: invite_id,
        inviteToken: token,
        status: status
    })
    #if response.success? && !api_contains_error("UpdateStatusForMembershipRequestToGroup", response)
    #  api_response = JSON.parse(response.response_body)["UpdateStatusForMembershipRequestToGroupResult"]
    redirect_to user_path(current_user_id)
    #end
  end

  def search_group
    @query = params[:query]
    api_response = nil
    if request.xhr?
      api_endpoint = "#{Settings.api_endpoints.GetGroupsForQuery}/#{current_user_id}/#{URI.escape(@query)}"
      response = Typhoeus.get(api_endpoint)
      if response.success? && !api_contains_error("GetGroupsForQuery", response)
        api_response = JSON.parse(response.response_body)["GetGroupsForQueryResult"]
      else
        api_response = {"error" => true}
      end
    else
      api_endpoint = "#{Settings.api_endpoints.GetOrganizersAndGroupForQuery}/#{current_user_id}/#{URI.escape(@query)}"
      response = Typhoeus.get(api_endpoint)
      if response.success? && !api_contains_error("GetOrganizersAndGroupForQuery", response)
        api_response = JSON.parse(response.response_body)["GetOrganizersAndGroupForQueryResult"]
        @groups = api_response["tagDetail"]
      else
        @groups = nil
        @organizers = nil
      end
    end

    if request.xhr?
      render :json => api_response.to_json
    else
      @groups = api_response.nil? ? nil : api_response["tagDetail"]
    end
  end

  def search_member_in_group
    tag_id = params[:tagID]
    query = URI.escape(params[:query])
    api_endpoint = "#{Settings.api_endpoints.GetMembersInGroupForQuery}/#{tag_id}/#{query}"
    response = Typhoeus.get(api_endpoint)
    api_response = nil
    if response.success? && !api_contains_error("GetMembersInGroupForQuery", response)
      api_response = JSON.parse(response.response_body)["GetMembersInGroupForQueryResult"]
      #@tags = api_response["tagDetail"]
    else
      api_response = {"error" => true}
    end
    render :json => api_response.to_json
  end

  def import_csv
    if !params[:csv].nil?
      if ["text/comma-separated-values","text/csv","application/csv","application/excel","application/vnd.ms-excel","application/vnd.msexcel","text/anytext"].include?(params[:csv].content_type)
        @email_array = []
        CSV.foreach(params[:csv].tempfile, :headers => true) do |row|
          row.each do |cell|
            cell.each do |email|
              matched_data = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/.match(email)
              unless matched_data.nil?
                @email_array << email
              end
            end
          end
        end
        if @email_array.blank?
          render :text => "NO_EMAIL" and return
        else
          render :partial => "import_csv_results"
        end
      else
        render :text => "INVALID_FORMAT" and return
      end
    end
  end

  def invite_imported_members
    tag_id = params[:tag_id]
    email_array = params[:emails]
    api_response = nil
    email_array.each_with_index do |email,i|
      api_endpoint = "#{Settings.api_endpoints.InviteMemberToGroupV1}"
      response = Typhoeus.post(api_endpoint, body: {
          adminUserId: current_user_id,
          invitedUserEmail: email,
          tagId: tag_id,
          invitedUserFirstName: email,
          invitedUserLastNameName: ""
      })
      if response.success? && !api_contains_error("InviteMemberToGroupV1", response)
        api_response = JSON.parse(response.response_body)["InviteMemberToGroupV1Result"]
      else
        api_response = {"error" => true}
      end
    end
    redirect_to group_path(tag_id)
  end

  protected

  def set_tab
    session[:selected_tab] = "groups"
    session[:active_tab] = ""
  end

end
