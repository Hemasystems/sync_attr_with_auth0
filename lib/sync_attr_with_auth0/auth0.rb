module SyncAttrWithAuth0
  module Auth0
    class InvalidAuth0ConfigurationException < StandardError; end

    require "auth0"
    require "uuidtools"

    def self.create_auth0_client(
      api_version: 2,
      config: SyncAttrWithAuth0.configuration
    )
      validate_auth0_config_for_api(api_version, config: config)

      auth0 = Auth0Client.new(
        client_id: config.auth0_client_id,
        client_secret: config.auth0_client_secret,
        domain: config.auth0_namespace
      )

      return auth0
    end # ::create_auth0_client


    def self.validate_auth0_config_for_api(api_version=2, config: SyncAttrWithAuth0.configuration)
      settings_to_validate = []
      invalid_settings = []

      settings_to_validate = [:auth0_client_id, :auth0_client_secret, :auth0_namespace]

      settings_to_validate.each do |setting_name|
        unless config.send(setting_name)
          invalid_settings << setting_name
        end
      end

      if invalid_settings.length > 0
        raise InvalidAuth0ConfigurationException.new("The following required auth0 settings were invalid: #{invalid_settings.join(', ')}")
      end
    end # ::validate_auth0_config_for_api


    def self.find_users_by_email(email, exclude_user_id: nil, config: SyncAttrWithAuth0.configuration)
      auth0 = SyncAttrWithAuth0::Auth0.create_auth0_client(config: config)

      # Use the Lucene search because Find by Email is case sensitive
      query = "email:#{email}"
      unless config.search_connections.empty?
        conn_query = config.search_connections
          .collect { |conn| %Q{identities.connection:"#{conn}"} }
          .join ' OR '
        query = "#{query} AND (#{conn_query})"
      end

      results = auth0.get('/api/v2/users', q: query, search_engine: 'v3')

      if exclude_user_id
        results = results.reject { |r| r['user_id'] == exclude_user_id }
      end

      return results
    end # ::find_users_by_email


    def self.create_user(params, config: SyncAttrWithAuth0.configuration)
      auth0 = SyncAttrWithAuth0::Auth0.create_auth0_client(config: config)
      return auth0.create_user(params.delete('connection'), params)
    end # ::create_user


    def self.patch_user(uid, params, config: SyncAttrWithAuth0.configuration)
      auth0 = SyncAttrWithAuth0::Auth0.create_auth0_client(config: config)

      return auth0.patch_user(uid, params)
    end # ::patch_user

  end
end
