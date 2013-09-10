require 'spec_helper'

describe "admin/groups/show" do
  before(:each) do
    @admin_group = assign(:admin_group, stub_model(Admin::Group,
      :index => "Index"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Index/)
  end
end
