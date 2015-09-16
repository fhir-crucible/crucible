class ServersController < ApplicationController

  def test
    @server = Server.find(params[:server_id])
    @tests = Test.all.sort {|l,r| l.name <=> r.name}
  end

end