class ServersController < ApplicationController

  def show
    @server = Server.find(params[:id])
    @tests = Test.all.sort {|l,r| l.name <=> r.name}
  end

  def create
    url = PostRank::URI.normalize(params['server']['url']).to_s.chop
    server = Server.where(url: url).first
    unless server
      server = Server.new(params.require(:server).permit(:name))
      server.url = url
      server.save
    end
    redirect_to action: "show", id: server.id
  end

  def oauth_redirect
    server = Server.where(state: params[:state]).first
    if server
      options = {
        authorize_url: server.authorize_url,
        token_url: server.token_url,
        raise_errors: false
      }
      client = OAuth2::Client.new(server.client_id, server.client_secret, options)
      auth_pw = Base64.encode64("#{server.client_id}:#{server.client_secret}")
      token = client.auth_code.get_token(params[:code], :redirect_uri => "http://#{env['HTTP_HOST']}/redirect", :headers => { 'Authorization' => "Basic #{auth_pw}" })
      server.oauth_token_opts = token.to_hash
      server.save!
      flash.notice = "Server successfully authorized"
      redirect_to server_path(server)
    else
      render status: 500, text: 'State not found'
    end
  end
end
