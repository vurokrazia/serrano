# frozen_string_literal: true

require 'json'
require 'stringio'
require 'minitest/autorun'
require 'rack/mock'
require_relative '../../lib/serrano'

class SerranoHttpCoreTest < Minitest::Test
  def with_suppressed_stderr
    original_stderr = $stderr
    $stderr = StringIO.new

    yield
  ensure
    $stderr = original_stderr
  end

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

  class MigrationErrorController
    def index(_request)
      raise StandardError, "SQLite3::SQLException: no such table: articles"
    end
  end

  class UsersController
    def new(_request)
      { route: 'static' }
    end

    def show(request)
      { id: request.params['id'], id_sugar: request['id'] }
    end
  end

  class PostsController
    def show(request)
      {
        user_id: request.params['user_id'],
        post_id: request.params['post_id']
      }
    end
  end

  class NilController
    def index(_request)
      nil
    end
  end

  class HeaderEchoController
    def show(_request)
      Serrano::Response.new(
        status: 202,
        headers: {
          'content-type' => 'text/plain',
          'x-serrano-test' => 'edge-case',
          'cache-control' => 'no-store'
        },
        body: 'ok'
      )
    end
  end

  class EmptyController; end

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
    response = nil
    with_suppressed_stderr do
      response = Rack::MockRequest.new(app).get('/crash')
    end

    assert_equal 500, response.status
    assert_includes response['content-type'], 'application/json'
    assert_equal({ 'error' => 'RuntimeError: boom' }, JSON.parse(response.body))
  end

  def test_database_schema_error_returns_clear_message
    app = Serrano::Application.new
    app.get('/migrate', MigrationErrorController, :index)
    response = nil
    with_suppressed_stderr do
      response = Rack::MockRequest.new(app).get('/migrate')
    end

    assert_equal 500, response.status
    assert_equal({ 'error' => 'Database schema is missing required table/column. Run migrations.' }, JSON.parse(response.body))
  end

  def test_dynamic_route_params_extraction_and_request_sugar
    app = Serrano::Application.new
    app.get('/users/:id', UsersController, :show)
    response = Rack::MockRequest.new(app).get('/users/42')

    assert_equal 200, response.status
    assert_includes response['content-type'], 'application/json'
    assert_equal({ 'id' => '42', 'id_sugar' => '42' }, JSON.parse(response.body))
  end

  def test_static_route_has_precedence_over_dynamic_route
    app = Serrano::Application.new
    app.get('/users/new', UsersController, :new)
    app.get('/users/:id', UsersController, :show)
    response = Rack::MockRequest.new(app).get('/users/new')

    assert_equal 200, response.status
    assert_equal({ 'route' => 'static' }, JSON.parse(response.body))
  end

  def test_multiple_dynamic_params_are_extracted
    app = Serrano::Application.new
    app.get('/users/:user_id/posts/:post_id', PostsController, :show)
    response = Rack::MockRequest.new(app).get('/users/7/posts/99')

    assert_equal 200, response.status
    assert_equal({ 'user_id' => '7', 'post_id' => '99' }, JSON.parse(response.body))
  end

  def test_405_allow_header_contains_only_registered_methods_and_is_lowercase
    app = Serrano::Application.new
    app.get('/users/:id', UsersController, :show)
    response = Rack::MockRequest.new(app).post('/users/10')

    assert_equal 405, response.status
    assert_equal 'GET', response.headers['allow']
    assert_includes response.headers.keys, 'allow'
    assert_equal response.headers.keys.map(&:downcase), response.headers.keys
  end

  def test_nil_return_currently_becomes_500_unsupported_response_type
    app = Serrano::Application.new
    app.get('/nil', NilController, :index)
    response = Rack::MockRequest.new(app).get('/nil')

    assert_equal 500, response.status
    assert_includes response['content-type'], 'text/plain'
    assert_equal 'Unsupported response type', response.body
  end

  def test_custom_response_headers_are_preserved
    app = Serrano::Application.new
    app.get('/headers', HeaderEchoController, :show)
    response = Rack::MockRequest.new(app).get('/headers')

    assert_equal 202, response.status
    assert_equal 'edge-case', response.headers['x-serrano-test']
    assert_equal 'no-store', response.headers['cache-control']
    assert_equal 'ok', response.body
  end

  def test_path_param_overrides_query_param
    app = Serrano::Application.new
    app.get('/users/:id', UsersController, :show)
    response = Rack::MockRequest.new(app).get('/users/42?id=9')

    assert_equal 200, response.status
    assert_equal({ 'id' => '42', 'id_sugar' => '42' }, JSON.parse(response.body))
  end

  def test_missing_controller_action_returns_500_json_without_stacktrace
    app = Serrano::Application.new
    app.get('/missing-action', EmptyController, :show)
    response = nil
    with_suppressed_stderr do
      response = Rack::MockRequest.new(app).get('/missing-action')
    end

    assert_equal 500, response.status
    assert_includes response['content-type'], 'application/json'
    parsed = JSON.parse(response.body)
    assert_match(%r{\ANoMethodError:\sundefined method 'show'}, parsed['error'])
    refute_includes response.body, 'backtrace'
  end
end
