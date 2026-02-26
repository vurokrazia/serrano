# frozen_string_literal: true

require 'json'

module Serrano
  class Response
    attr_reader :status, :headers, :body

    def initialize(status: 200, headers: {}, body: '')
      @status = status
      @headers = headers
      @body = body
    end

    def to_rack
      [status, headers, [body.to_s]]
    end

    def self.normalize(result)
      case result
      when Response
        result.to_rack
      when String
        new(body: result, headers: { 'content-type' => 'text/plain' }).to_rack
      when Hash
        new(body: JSON.generate(result), headers: { 'content-type' => 'application/json' }).to_rack
      else
        new(status: 500, body: 'Unsupported response type',
            headers: { 'content-type' => 'text/plain' }).to_rack
      end
    end
  end
end
