class SMARTOAuth
  include Mongoid::Document
  field :client_id, type: String, default: "00000000-0000-0000-0000-000000000000"
  field :scopes, type: String, default: "launch openid profile patient/*.read"
  field :base_url, type: String, default: ""
  field :redirect_url, type: String, default: "http://localhost:3000/smart/app"

end
