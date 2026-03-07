# frozen_string_literal: true

require "minitest/autorun"
require "rack/mock"
require_relative "../../lib/serrano"

class SerranoRequestTest < Minitest::Test
  def test_params_merges_query_and_body_when_body_is_present
    env = Rack::MockRequest.env_for(
      "/articles?filter=recent",
      method: "POST",
      input: "title=First&content=Hello",
      "CONTENT_TYPE" => "application/x-www-form-urlencoded",
      "CONTENT_LENGTH" => "20"
    )
    request = Serrano::Request.new(env)
    request.set_path_params("id" => "42")

    assert_equal(
      {
        "filter" => "recent",
        "title" => "First",
        "content" => "Hello",
        "id" => "42"
      },
      request.params
    )
    assert_equal "First", request["title"]
  end

  def test_params_ignores_body_when_content_length_is_zero
    env = Rack::MockRequest.env_for(
      "/articles?filter=recent",
      method: "POST",
      input: "title=First&content=Hello",
      "CONTENT_TYPE" => "application/x-www-form-urlencoded",
      "CONTENT_LENGTH" => "0"
    )
    request = Serrano::Request.new(env)

    assert_equal({ "filter" => "recent" }, request.params)
  end

  def test_body_reads_raw_when_available
    env = Rack::MockRequest.env_for(
      "/articles",
      method: "POST",
      input: "raw body",
      "CONTENT_LENGTH" => "8"
    )
    request = Serrano::Request.new(env)

    assert_equal "raw body", request.body
  end

  def test_headers_maps_http_env_keys
    env = Rack::MockRequest.env_for(
      "/articles",
      method: "GET",
      "HTTP_X_TEST_TOKEN" => "abc",
      "HTTP_X_OTHER" => "1"
    )
    request = Serrano::Request.new(env)

    assert_equal "abc", request.headers["X-Test-Token"]
    assert_equal "1", request.headers["X-Other"]
  end
end
