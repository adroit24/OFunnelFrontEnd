require 'spec_helper'

describe "admin/groups/new" do
  before(:each) do
    assign(:admin_group, stub_model(Admin::Group,
      :index => "MyString"
    ).as_new_record)
  end

  it "renders new admin_group form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", admin_groups_path, "post" do
      assert_select "input#admin_group_index[name=?]", "admin_group[index]"
    end
  end
end
