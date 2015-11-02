MagicLamp.define(controller: ServersController) do
  fixture do # servers/show
    @server = Server.new(url: 'www.example.com')
    @tests = Test.all.sort {|l,r| l.name <=> r.name}
    render :show
  end  
end