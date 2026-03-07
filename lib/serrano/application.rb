# frozen_string_literal: true

require 'rack'

module Serrano
  class Application
    def initialize
      @router = Router.new
      @dispatcher = Dispatcher.new(@router)
    end

    def get(path, controller, action)
      @router.add('GET', path, controller, action)
    end

    def post(path, controller, action)
      @router.add('POST', path, controller, action)
    end

    def put(path, controller, action)
      @router.add('PUT', path, controller, action)
    end

    def delete(path, controller, action)
      @router.add('DELETE', path, controller, action)
    end

    def call(env)
      @dispatcher.call(env)
    end

    def run!(host: '0.0.0.0', port: 9292)
      Rack::Handler::WEBrick.run(self, Host: host, Port: port)
    end
  end
end
