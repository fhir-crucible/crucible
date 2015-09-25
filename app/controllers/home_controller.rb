class HomeController < ApplicationController
  # before_action :authenticate_user!

  def index
  	@servers = Server.all.order_by("percent_passing"=>:desc)
  end

end
