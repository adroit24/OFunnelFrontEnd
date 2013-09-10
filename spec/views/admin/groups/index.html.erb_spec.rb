require 'spec_helper'

describe "admin/groups/index" do
  before(:each) do
    assign(:admin_groups, [
      stub_model(Admin::Group,
        :index => "Index"
      ),
      stub_model(Admin::Group,
        :index => "Index"
      )
    ])
  end

  it "renders a list of admin/groups" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Index".to_s, :count => 2
  end
end
