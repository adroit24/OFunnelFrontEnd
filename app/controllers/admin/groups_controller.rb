class Admin::GroupsController < ApplicationController
  before_filter :check_current_user
  layout "admin/application"

  # GET /admin/groups
  # GET /admin/groups.json
  def index
    api_endpoint = "#{Settings.api_endpoints.GetAllPendingStatusGroups}"
    response = Typhoeus.get(api_endpoint)
    if response.success? && !api_contains_error("GetAllPendingStatusGroups", response)
      @admin_groups = JSON.parse(response.response_body)["GetAllPendingStatusGroupsResult"]
    else
      @admin_groups = nil
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @admin_groups }
    end
  end

  def admin_index

  end

  def import_companies
    if !params[:xls].nil?
      name = params[:xls].original_filename
      directory = "public/xls"
      path = File.join(directory, name)

      File.open(path, "wb") { |f| f.write(params[:xls].read) }
      companies_sheet = nil
      case File.extname(path)
        when ".xlsx"
          companies_sheet = Roo::Excelx.new(path)
        when ".xls"
          companies_sheet = Roo::Excel.new(path)
        else
          companies_sheet = Roo::Openoffice.new(path)
      end

      unless companies_sheet.nil?
        companies_sheet.default_sheet = companies_sheet.sheets.first
      end
      p companies_sheet
      File.delete(path)
    end
  end

  # GET /admin/groups/1
  # GET /admin/groups/1.json
  def show
    @admin_group = nil

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @admin_group }
    end
  end

  # GET /admin/groups/new
  # GET /admin/groups/new.json
  def new
    @admin_group = nil

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @admin_group }
    end
  end

  # GET /admin/groups/1/edit
  def edit
    group_id = params[:id]
    status = params[:status]
    api_endpoint = "#{Settings.api_endpoints.UpdateGroupStatus}"
    response = Typhoeus.post(api_endpoint, body: {
        tagId: group_id,
        status: status
    })
    redirect_to admin_groups_path
  end

  # POST /admin/groups
  # POST /admin/groups.json
  def create
    @admin_group = Admin::Group.new(params[:admin_group])

    respond_to do |format|
      if @admin_group.save
        format.html { redirect_to @admin_group, notice: 'Group was successfully created.' }
        format.json { render json: @admin_group, status: :created, location: @admin_group }
      else
        format.html { render action: "new" }
        format.json { render json: @admin_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /admin/groups/1
  # PUT /admin/groups/1.json
  def update
    @admin_group = Admin::Group.find(params[:id])

    respond_to do |format|
      if @admin_group.update_attributes(params[:admin_group])
        format.html { redirect_to @admin_group, notice: 'Group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @admin_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/groups/1
  # DELETE /admin/groups/1.json
  def destroy
    @admin_group = Admin::Group.find(params[:id])
    @admin_group.destroy

    respond_to do |format|
      format.html { redirect_to admin_groups_url }
      format.json { head :no_content }
    end
  end
end
