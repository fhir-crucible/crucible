require './config/oauth.rb'

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

  private
  def set_oauth
    @oauth_data = Crucible::SMART::OAuth.get_config
  end
end
