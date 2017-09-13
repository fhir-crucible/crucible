class SMARTOAuth
  include Mongoid::Document

  field :client_id, type: String, default: "00000000-0000-0000-0000-000000000000"
  field :scopes, type: String, default: "launch openid profile patient/*.read"

  def self.base_url
    ""
  end

  def self.redirect_url
    "http://localhost:3000/smart/app"
  end

end
