# frozen_string_literal: true

require 'rack'

module Serrano
  class Request
    def initialize(env)
      @env = env
      @path_params = {}
    end

    def method
      env['REQUEST_METHOD']
    end

    def path
      env['PATH_INFO']
    end

    def params
      @params ||= begin
        req = rack_request
        req.GET.merge(req.POST).merge(@path_params)
      end
    end

    def set_path_params(path_params)
      @path_params = path_params
      @params = nil
    end

    def headers
      @headers ||= env.each_with_object({}) do |(key, value), memo|
        next unless key.start_with?('HTTP_')

        header_name = key.sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-')
        memo[header_name] = value
      end
    end

    def body
      io = env['rack.input']
      return '' unless io

      @body ||= begin
        io.rewind if io.respond_to?(:rewind)
        io.read.to_s
      end
    end

    def [](key)
      params[key]
    end

    private

    attr_reader :env

    def rack_request
      @rack_request ||= Rack::Request.new(env)
    end
  end
end
