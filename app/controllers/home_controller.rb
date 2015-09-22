class HomeController < ApplicationController
  # before_action :authenticate_user!

  def index
  	@servers = Server.order_by('percent_passing' => :desc).to_a
  end

end
