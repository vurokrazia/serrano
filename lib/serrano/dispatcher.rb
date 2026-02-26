# frozen_string_literal: true

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
    rescue StandardError
      Response.new(
        status: 500,
        headers: { 'content-type' => 'application/json' },
        body: '{"error":"Internal Server Error"}'
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
  end
end
