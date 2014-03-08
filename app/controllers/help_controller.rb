class HelpController < ApplicationController

  layout "relationships"
  before_filter :check_current_user

  def index
  end

end
