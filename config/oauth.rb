module Crucible
  module SMART
    class OAuth

      # Load the client_ids and scopes from a configuration file
      OAUTH = YAML.load(File.open(File.join(File.dirname(File.absolute_path(__FILE__)),'oauth.yml'),'r:UTF-8',&:read))

      # Given a URL, choose a client_id to use
      def self.get_client_id(url)
        return nil unless url
        OAUTH['client_id'].each do |key,value|
          return value if url.include?(key)
        end
        nil
      end

      # Given a URL, choose the OAuth2 scopes to request
      def self.get_scopes(url)
        return nil unless url
        OAUTH['scopes'].each do |key,value|
          return value if url.include?(key)
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
        OAUTH['client_id'].each do |client,client_id|
          scopes = OAUTH['scopes'][client]
          rows << { client: client, client_id: client_id, scopes: scopes }
        end
        rows
      end

      # Add a client ID and scopes to the CONFIGURATION
      def self.add_client(name,client_id,scopes)
        OAUTH['client_id'][name] = client_id
        OAUTH['scopes'][name] = scopes
        save
      end

      # Delete a client ID and scopes from the CONFIGURATION
      def self.delete_client(name)
        OAUTH['client_id'].delete(name)
        OAUTH['scopes'].delete(name)
        save
      end

      # Save the current state of the CONFIGURATION to the config.yml file.
      def self.save
        File.open(File.join(File.dirname(File.absolute_path(__FILE__)),'..','oauth.yml'),'w:UTF-8') do |file|
          file.write OAUTH.to_yaml
        end
      end

    end
  end
end
