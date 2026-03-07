# frozen_string_literal: true

require 'json'

module Serrano
  class Dispatcher
    def initialize(router)
      @router = router
    end

    def call(env)
      request = Request.new(env)
      route = @router.resolve(request.method, request.path)

      unless route
        allowed_methods = @router.allowed_methods(request.path)
        return method_not_allowed(allowed_methods) unless allowed_methods.empty?

        return not_found
      end

      controller = route[:controller].new
      request.set_path_params(route[:path_params] || {})
      result = controller.public_send(route[:action], request)
      Response.normalize(result)
    rescue StandardError => error
      Response.new(
        status: 500,
        headers: { 'content-type' => 'application/json' },
        body: JSON.generate(error: user_friendly_error_message(error))
      ).to_rack
    end

    private

    def method_not_allowed(allowed_methods)
      Response.new(
        status: 405,
        headers: {
          'content-type' => 'application/json',
          'allow' => allowed_methods.sort.join(', ')
        },
        body: '{"error":"Method Not Allowed"}'
      ).to_rack
    end

    def not_found
      Response.new(
        status: 404,
        headers: { 'content-type' => 'application/json' },
        body: '{"error":"Not Found"}'
      ).to_rack
    end

    def user_friendly_error_message(error)
      migration_hint(error.message) || "#{error.class}: #{error.message}"
    end

    def migration_hint(message)
      return nil if message.nil?

      normalized = message.downcase
      return 'Database schema is missing required table/column. Run migrations.' if normalized.match?(%r{
        no\ such\ table|no\ such\ column|doesn't\ exist|relation\ .*\ does\ not\ exist|table\ .*\ does\ not\ exist|unknown\ column
      }x)

      nil
    end
  end
end
