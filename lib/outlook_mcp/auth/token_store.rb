# frozen_string_literal: true

module OutlookMcp
  module Auth
    class TokenStore
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def tokens
        return nil unless File.exist?(config.token_path)

        JSON.parse(File.read(config.token_path), symbolize_names: true)
      end

      def save(token_data)
        token_data[:expires_at] = Time.now.to_i + token_data[:expires_in].to_i
        File.write(config.token_path, JSON.pretty_generate(token_data))
      end

      def access_token
        data = tokens
        raise "No tokens found. Run `outlook-mcp auth` first." unless data

        refresh! if expired?(data)
        tokens[:access_token]
      end

      def expired?(data = tokens)
        return true unless data&.dig(:expires_at)

        Time.now.to_i >= data[:expires_at] - 300
      end

      def refresh!
        data = tokens
        raise "No refresh token available" unless data&.dig(:refresh_token)

        oauth = OAuthClient.new(config)
        new_data = oauth.refresh_token(data[:refresh_token])
        save(new_data)
      end
    end
  end
end
