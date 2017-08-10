require './config/oauth'

class SmartsController < ApplicationController
  before_filter :set_oauth

  def index
  end

  def app
  end

  def launch
  end

  def cfg
  end

  def update_cfg
    if params['delete']
      puts "Deleting configuration: #{params['delete']}"
      Crucible::SMART::OAuth.delete_client(params['delete'])
    else
      puts "Saving configuration: #{params}"
      Crucible::SMART::OAuth.add_client(params['Server'],params['Client ID'],params['Scopes'])
    end
    puts "Configuration saved."
    @oauth_data = Crucible::SMART::OAuth.get_config
    redirect_to "/smart/cfg"
  end

  private
  def set_oauth
    @oauth_data = Crucible::SMART::OAuth.get_config
  end
end
