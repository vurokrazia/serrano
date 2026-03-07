# Serrano - Full Examples

This document is the usage cookbook for the framework and CLI.

## 1) Core Runtime: Minimal HTTP App

### 1.1 files

`config.ru`:

```ruby
# frozen_string_literal: true

require "serrano"

class UsersController
  def index(_request)
    { users: [] }
  end

  def show(request)
    { id: request.params['id'], via_query: request.params['foo'] }
  end
end

app = Serrano::Application.new
app.get "/users", UsersController, :index
app.get "/users/:id", UsersController, :show

run app
```

### 1.2 start and test

```bash
bundle exec rackup
curl -i http://localhost:9292/users
curl -i http://localhost:9292/users/12?foo=abc
```

Expected:
- `GET /users` => `200 application/json`
- `GET /users/12?foo=abc` => `200 application/json` and body contains `{"id":"12","via_query":"abc"}`

---

## 2) Return Contract

### 2.1 Hash response

```ruby
def index(_request)
  { ok: true, count: 10 }
end
```

### 2.2 String response

```ruby
def ping(_request)
  "pong"
end
```

### 2.3 Custom response object

```ruby
def create(_request)
  Serrano::Response.new(
    status: 201,
    headers: { "content-type" => "application/json" },
    body: '{"created":true}'
  )
end
```

### 2.4 Error handling

```ruby
def crash(_request)
  raise 'boom'
end
```

- status `500`
- body `{"error":"RuntimeError: boom"}`

---

## 3) Routing behaviors

### 3.1 Static vs dynamic precedence

```ruby
app.get "/users/new", UsersController, :new
app.get "/users/:id", UsersController, :show
```

`GET /users/new` must resolve to `:new` route.

### 3.2 Multiple dynamic params

```ruby
app.get "/users/:user_id/posts/:post_id", PostsController, :show
```

### 3.3 405 when method exists for another verb

If only `GET /users/:id` exists and you request `POST /users/1`:

- `405`
- body `{"error":"Method Not Allowed"}`
- header `allow` containing only allowed methods

---

## 4) Request Object Helpers

```ruby
# In controller action
request.path
request.method
request.params
request.headers
request.body
request['id']
```

`request['id']` is sugar for `request.params['id']`.

---

## 5) CLI: bootstrap new projects

Use:

```bash
bundle exec serrano new my_app
```

## 5.1 create full project (recommended)

```bash
bundle exec serrano new my_app
```

Generated structure includes `app/`, `config.ru`, `Gemfile`, `config/db.rb`, `db/migrations/`.

## 5.2 create full project + sqlite db

```bash
bundle exec serrano new my_app --db=sqlite
```

Adds sqlite dependency and DB config.

## 5.3 minimal project

```bash
bundle exec serrano new my_app --minimal
```

Only boot files, no app/db scaffolding.

## 5.4 minimal + db

```bash
bundle exec serrano new my_app --minimal --db=postgres
```

Orthogonal behavior: `--minimal` does not disable DB files.

Next steps after `new`:

```bash
cd my_app
bundle install
bundle exec rackup
```

---

## 6) CLI generate commands

### 6.1 scaffold full resource

```bash
bundle exec serrano generate resource Article title:string content:text
```

Creates:

- `app/controllers/articles_controller.rb`
- `app/services/articles/{index,show,create,update,destroy}.rb`
- `app/repositories/article_repository.rb`
- `app/entities/article.rb`
- `db/migrations/*_create_articles.rb`
- route suggestions printed in terminal (print-only)

### 6.2 generate individual files

```bash
bundle exec serrano generate controller Comments
bundle exec serrano generate service Reports::Monthly
bundle exec serrano generate repository Comment
```

---

## 7) Full CRUD example flow with articles resource

This example assumes you are inside an app where `generate resource` already created files.

### 7.1 Start server

```bash
bundle exec rackup
```

### 7.2 routes examples

```bash
curl -i http://localhost:9292/articles
curl -i http://localhost:9292/articles/1
curl -i -X POST http://localhost:9292/articles \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-raw "title=First&content=Hello"
curl -i -X PUT http://localhost:9292/articles/1 \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-raw "title=Updated&content=Changed"
curl -i -X DELETE http://localhost:9292/articles/1
```

Expected mapping:

- `GET /articles` -> `index`
- `GET /articles/:id` -> `show`
- `POST /articles` -> `create`
- `PUT /articles/:id` -> `update`
- `DELETE /articles/:id` -> `destroy`

### 7.3 pass params

```bash
curl -i "http://localhost:9292/articles/1?source=cli"
curl -i -X POST "http://localhost:9292/articles" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data "title=First&content=Hello"
```

---

## 8) Error demos to reproduce and validate

### 8.1 404

```bash
curl -i http://localhost:9292/does-not-exist
```

Expect `404` JSON `{"error":"Not Found"}`.

### 8.2 405

If route only has `GET`, call with `POST`/`PUT`/`DELETE` to same path and confirm `405` + `allow`.

### 8.3 500

Use a crashing action in controller:

```ruby
def crash(_request)
  raise StandardError, 'boom'
end
```

Expect:

- `500`
- body `{"error":"StandardError: boom"}`

---

## 9) Note on `config.ru` in generated resources

The CLI keeps route insertion explicit and deterministic. If you scaffold in an empty `config.ru`, check and adjust routes manually when needed, especially if you want custom middleware or custom boot flow.
