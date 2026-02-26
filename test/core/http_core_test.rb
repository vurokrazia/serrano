# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require 'rack/mock'
require_relative '../../lib/serrano'

class SerranoHttpCoreTest < Minitest::Test
  class HashController
    def index(_request)
      { message: 'ok' }
    end
  end

  class CustomResponseController
    def create(_request)
      Serrano::Response.new(
        status: 201,
        headers: { 'content-type' => 'application/json' },
        body: '{"created":true}'
      )
    end
  end

  class ErrorController
    def crash(_request)
      raise 'boom'
    end
  end

  class UsersController
    def show(request)
      { id: request.params['id'], id_sugar: request['id'] }
    end
  end

  def test_hash_return_is_normalized_to_200_json
    app = Serrano::Application.new
    app.get('/ping', HashController, :index)
    response = Rack::MockRequest.new(app).get('/ping')

    assert_equal 200, response.status
    assert_includes response['content-type'], 'application/json'
    assert_equal({ 'message' => 'ok' }, JSON.parse(response.body))
  end

  def test_serrano_response_preserves_custom_status
    app = Serrano::Application.new
    app.post('/items', CustomResponseController, :create)
    response = Rack::MockRequest.new(app).post('/items')

    assert_equal 201, response.status
    assert_includes response['content-type'], 'application/json'
    assert_equal({ 'created' => true }, JSON.parse(response.body))
  end

  def test_unknown_route_returns_404_json
    app = Serrano::Application.new
    response = Rack::MockRequest.new(app).get('/missing')

    assert_equal 404, response.status
    assert_includes response['content-type'], 'application/json'
    assert_equal({ 'error' => 'Not Found' }, JSON.parse(response.body))
  end

  def test_controller_exception_returns_500_json
    app = Serrano::Application.new
    app.get('/crash', ErrorController, :crash)
    response = Rack::MockRequest.new(app).get('/crash')

    assert_equal 500, response.status
    assert_includes response['content-type'], 'application/json'
    assert_equal({ 'error' => 'Internal Server Error' }, JSON.parse(response.body))
  end

  def test_dynamic_route_params_extraction_and_request_sugar
    app = Serrano::Application.new
    app.get('/users/:id', UsersController, :show)
    response = Rack::MockRequest.new(app).get('/users/42')

    assert_equal 200, response.status
    assert_includes response['content-type'], 'application/json'
    assert_equal({ 'id' => '42', 'id_sugar' => '42' }, JSON.parse(response.body))
  end
end
