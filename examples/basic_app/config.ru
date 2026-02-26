# frozen_string_literal: true

require_relative "../../lib/serrano"
require_relative "./app/controllers/users_controller"

app = Serrano::Application.new
app.get "/users", UsersController, :index
app.get "/users/:id", UsersController, :show
app.post "/users", UsersController, :create
app.get "/crash", UsersController, :crash

run app