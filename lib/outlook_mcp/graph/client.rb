# frozen_string_literal: true

module OutlookMcp
  module Graph
    class Client
      include Email
      include Folder
      prepend SanitizeIds.wrap(Email)
      prepend SanitizeIds.wrap(Folder)

      BASE_URL = "https://graph.microsoft.com"
      API_VERSION = "/v1.0"

      def initialize(token_store)
        @token_store = token_store
      end

      def get(path, params = {})
        request(:get, path, params)
      end

      def post(path, body = {})
        request(:post, path, body)
      end

      def patch(path, body = {})
        request(:patch, path, body)
      end

      def delete(path)
        request(:delete, path)
      end

      private

      def connection
        @connection ||= Faraday.new(url: BASE_URL) do |f|
          f.request :json
          f.response :json
          f.response :raise_error
        end
      end

      def request(method, path, body_or_params = nil)
        retried = false
        full_path = "#{API_VERSION}#{path}"
        begin
          response = connection.public_send(method, full_path) do |req|
            req.headers["Authorization"] = "Bearer #{@token_store.access_token}"
            if method == :get
              body_or_params&.each { |k, v| req.params[k] = v }
            else
              req.body = body_or_params if body_or_params
            end
          end
          response.body
        rescue Faraday::UnauthorizedError
          raise if retried

          retried = true
          @token_store.refresh!
          retry
        end
      end
    end
  end
end
