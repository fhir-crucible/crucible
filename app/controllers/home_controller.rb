class HomeController < ApplicationController
  # before_action :authenticate_user!

  def index
  	#@servers = Server.all.order_by("percent_passing"=>:desc)
  	# show all until issue is resolved
  	@servers = Server.where({percent_passing: {"$gte" => 0}}).order_by("percent_passing"=>:desc)
  end

end
