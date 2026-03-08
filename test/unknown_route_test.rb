# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require 'rack/mock'
require_relative '../lib/serrano'

APP = Serrano::Application.new

class UnknownRouteTest < Minitest::Test
  def setup
    @request = Rack::MockRequest.new(APP)
  end

  def test_unknown_path_returns_json_404
    response = @request.get('/missing')

    assert_equal 404, response.status
    assert_includes response.headers['content-type'], 'application/json'
    assert_equal({ 'error' => 'Not Found', 'path' => '/missing' }, JSON.parse(response.body))
  end
end
