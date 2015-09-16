module Api
  class SessionsController < Devise::SessionsController
    clear_respond_to
    respond_to :json

    def create
      super do |user|
        data = {
          token: user.authentication_token,
          email: user.email
        }
        render json: data, status: 201 and return
      end
    end
  end
end
