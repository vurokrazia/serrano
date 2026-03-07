# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "rack/mock"
require_relative "../../lib/serrano"

class SerranoApplicationTest < Minitest::Test
  class ArticlesController
    def destroy(_request)
      Serrano::Response.new(
        status: 200,
        headers: { "content-type" => "application/json" },
        body: '{"deleted":true}'
      )
    end
  end

  def test_delete_route_is_routed_and_executed
    app = Serrano::Application.new
    app.delete("/articles/:id", ArticlesController, :destroy)

    response = Rack::MockRequest.new(app).delete("/articles/15")

    assert_equal 200, response.status
    assert_equal({ "deleted" => true }, JSON.parse(response.body))
  end

  def test_method_not_allowed_for_existing_path
    app = Serrano::Application.new
    app.get("/articles/:id", ArticlesController, :destroy)

    response = Rack::MockRequest.new(app).delete("/articles/15")

    assert_equal 405, response.status
    assert_equal "GET", response.headers["allow"]
    assert_equal({ "error" => "Method Not Allowed" }, JSON.parse(response.body))
  end
end
