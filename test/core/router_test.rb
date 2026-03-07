# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/serrano/router"

class SerranoRouterTest < Minitest::Test
  class SampleController
    def index(_request); end
  end

  def test_supported_verbs_include_delete
    router = Serrano::Router.new
    router.add("DELETE", "/items/:id", SampleController, :index)

    route = router.resolve("DELETE", "/items/10")

    assert_equal SampleController, route[:controller]
    assert_equal :index, route[:action]
    assert_equal({ "id" => "10" }, route[:path_params])
  end

  def test_static_route_takes_priority_over_dynamic_route
    router = Serrano::Router.new
    router.add("GET", "/users/new", SampleController, :index)
    router.add("GET", "/users/:id", SampleController, :index)

    route = router.resolve("GET", "/users/new")

    assert_equal({}, route[:path_params])
  end

  def test_allowed_methods_only_for_matching_path
    router = Serrano::Router.new
    router.add("GET", "/users", SampleController, :index)
    router.add("PUT", "/users/:id", SampleController, :index)
    router.add("DELETE", "/users/:id", SampleController, :index)

    assert_equal ["GET"], router.allowed_methods("/users")
    assert_includes router.allowed_methods("/users/10"), "PUT"
    assert_includes router.allowed_methods("/users/10"), "DELETE"
    assert_equal 0, router.allowed_methods("/missing").count
  end
end
