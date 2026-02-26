# frozen_string_literal: true

class UsersController
  def index(request)
    {
      message: 'users index',
      method: request.method,
      path: request.path,
      params: request.params
    }
  end

  def show(request)
    if request['id'] == '7'
      return Serrano::Response.new(
        status: 403,
        headers: { 'content-type' => 'application/json' },
        body: '{"error":"Forbidden"}'
      )
    end

    {
      message: 'users show',
      method: request.method,
      path: request.path,
      params: request.params
    }
  end

  def create(request)
    {
      message: 'users create',
      method: request.method,
      path: request.path,
      params: request.params,
      body: request.body
    }
  end

  def crash(_request)
    raise 'boom'
  end
end
