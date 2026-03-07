# frozen_string_literal: true

module Serrano
  class Router
    SUPPORTED_METHODS = %w[GET POST PUT DELETE].freeze

    def initialize
      @routes = SUPPORTED_METHODS.to_h { |method| [method, {}] }
    end

    def add(method, path, controller, action)
      method_key = normalize_method(method)
      @routes[method_key][path] = { controller: controller, action: action }
    end

    def resolve(method, path)
      method_key = normalize_method(method)
      method_routes = @routes.fetch(method_key, {})

      exact_route = method_routes[path]
      return exact_route_response(exact_route) if exact_route

      method_routes.each do |pattern, route|
        path_params = extract_path_params(pattern, path)
        next unless path_params

        return route.merge(path_params: path_params)
      end

      nil
    end

    def allowed_methods(path)
      @routes.each_with_object([]) do |(method, method_routes), allowed|
        allowed << method if route_exists_for_path?(method_routes, path)
      end
    end

    private

    def normalize_method(method)
      method.to_s.upcase
    end

    def exact_route_response(route)
      route.merge(path_params: {})
    end

    def route_exists_for_path?(method_routes, path)
      method_routes.any? { |pattern, _| path_match?(pattern, path) }
    end

    def path_match?(pattern, path)
      !extract_path_params(pattern, path).nil?
    end

    def extract_path_params(pattern, path)
      pattern_segments = split_path(pattern)
      path_segments = split_path(path)
      return nil unless pattern_segments.length == path_segments.length

      params = {}

      pattern_segments.each_with_index do |segment, index|
        value = path_segments[index]
        if segment.start_with?(':')
          params[segment.delete_prefix(':')] = value
        elsif segment != value
          return nil
        end
      end

      params
    end

    def split_path(path)
      path.to_s.split('/').reject(&:empty?)
    end
  end
end
