# frozen_string_literal: true

module OutlookMcp
  module Auth
    class OAuthClient
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def authorization_url
        params = URI.encode_www_form(
          client_id: config.client_id,
          response_type: "code",
          redirect_uri: config.redirect_uri,
          scope: config.scopes,
          response_mode: "query"
        )
        "#{config.authorize_url}?#{params}"
      end

      def exchange_code(code)
        response = token_request(
          grant_type: "authorization_code",
          code: code,
          redirect_uri: config.redirect_uri
        )
        parse_token_response(response)
      end

      def refresh_token(refresh_token)
        response = token_request(
          grant_type: "refresh_token",
          refresh_token: refresh_token
        )
        parse_token_response(response)
      end

      private

      def token_request(params)
        conn = Faraday.new do |f|
          f.request :url_encoded
          f.response :json
        end

        conn.post(config.token_url, {
          client_id: config.client_id,
          client_secret: config.client_secret,
          scope: config.scopes,
          **params
        })
      end

      def parse_token_response(response)
        data = response.body
        if data["error"]
          raise "OAuth error: #{data["error_description"] || data["error"]}"
        end

        data.transform_keys(&:to_sym)
      end
    end
  end
end
