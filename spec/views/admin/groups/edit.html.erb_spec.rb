require 'spec_helper'

describe "admin/groups/edit" do
  before(:each) do
    @admin_group = assign(:admin_group, stub_model(Admin::Group,
      :index => "MyString"
    ))
  end

  it "renders the edit admin_group form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", admin_group_path(@admin_group), "post" do
      assert_select "input#admin_group_index[name=?]", "admin_group[index]"
    end
  end
end
