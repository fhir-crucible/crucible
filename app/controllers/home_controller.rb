class HomeController < ApplicationController
  # before_action :authenticate_user!

  def index
  	@servers = Server.all
  end

end
