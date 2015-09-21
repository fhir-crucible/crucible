class ServersController < ApplicationController

  def show
    @server = Server.find(params[:id])
    @tests = Test.all.sort {|l,r| l.name <=> r.name}
  end

  def create
    url = PostRank::URI.normalize(params['server']['url'])
    server = Server.where(url: url).first
    server = Server.new(params.require(:server).permit(:url, :name)) unless server
    redirect_to action: "show", id: server.id
  end

end