# frozen_string_literal: true

require "json"

require_relative "../services/articles/create"

class ArticlesController
  def create(request)
    result = Articles::Services::Create.new.call(request.params)

    if result[:ok]
      return Serrano::Response.new(
        status: 201,
        headers: { "content-type" => "application/json" },
        body: JSON.generate(result[:article].to_h)
      )
    end

    Serrano::Response.new(
      status: 422,
      headers: { "content-type" => "application/json" },
      body: JSON.generate({ errors: result[:errors] })
    )
  end
end