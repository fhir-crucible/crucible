module Api
  class UsersController < ApplicationController
  	
    before_action :authenticate_user!
    respond_to :json

    def index
      render json: User.all
    end

    def show
      user = User.find(params[:id])
      respond_with user
    end
  end

end
