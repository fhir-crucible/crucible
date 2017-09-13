module Crucible
  module SMART
    class OAuth

      # Load the client_ids and scopes from a configuration file
      OAUTH = SmartClient.all
      base_url = ""
      redirect_url = "http://localhost:3000/smart/app"

      # Given a URL, choose a client_id to use
      def self.get_client_id(url)
        return nil unless url
        OAUTH.each do |client|
          return client.id if url.include?(client.name)
        end
        nil
      end

      # Given a URL, choose the OAuth2 scopes to request
      def self.get_scopes(url)
        return nil unless url
        OAUTH.each do |client|
          return client.scopes if url.include?(client.name)
        end
        nil
      end

      # Extract the Authorization and Token URLs
      # from the FHIR Conformance
      def self.get_auth_info(issuer)
        return {} unless issuer
        client = FHIR::Client.new(issuer)
        client.default_json
        client.get_oauth2_metadata_from_conformance
      end

      def self.get_config
        rows = []
        OAUTH.each do |client|
          rows << { client: client.name, client_id: client.id, scopes: client.scopes }
        end
        rows
      end

      # Add a client ID and scopes to the CONFIGURATION
      def self.add_client(name,client_id,scopes)
        client = SmartClient.new
        client.name = name
        client.id = client_id
        client.scopes = scopes
        client.save
      end

      # Delete a client ID and scopes from the CONFIGURATION
      def self.delete_client(name)
        client = SmartClient.find_by(name: name)
        client.destroy if client
      end

    end
  end
end
