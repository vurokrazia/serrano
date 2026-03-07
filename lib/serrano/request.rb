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
        req.GET.merge(post_params(req)).merge(@path_params)
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

    def post_params(request)
      return {} unless parseable_body?

      request.POST
    rescue StandardError
      {}
    end

    def parseable_body?
      content_length = env["CONTENT_LENGTH"].to_s
      transfer_encoding = env["HTTP_TRANSFER_ENCODING"].to_s

      content_length != "" && content_length != "0" || transfer_encoding != ""
    end
  end
end
