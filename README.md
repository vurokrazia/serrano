# Serrano

Minimal Rack-based Ruby microframework focused on explicit HTTP contracts and architectural clarity.

---

## What is Serrano

Serrano is a minimal HTTP runtime built on Rack. It provides route resolution, request dispatching, and small request/response abstractions for controller-based applications.

Serrano does not include an ORM, middleware stack, generators, or predefined architecture layers. The core is intentionally explicit and predictable.

---

## Philosophy

- Explicit over magic
- Minimal surface area
- Deterministic controller return contract
- No hidden behavior
- Clear separation between framework core and application architecture
- HTTP-first design

Serrano keeps the framework core small so request flow is easy to understand and reason about. Routing, dispatching, and response normalization are explicit and visible in code.

It avoids built-in ORM, middleware stacks, and heavy abstractions to prevent implicit coupling. Data access, services, repositories, and other architectural choices are application concerns, not framework defaults.

---

## Installation

- Ruby `>= 3.2` required
- Compatible with Ruby `3.4+`

Local development usage (path gem):

```ruby
gem "serrano", path: "../serrano"
```

Serrano is currently intended for local usage and is not published as a remote gem.

---

## Core Quick Start

1. `config.ru`

```ruby
# frozen_string_literal: true

require_relative "./lib/serrano"

class UsersController
  def index(_request)
    { users: [] }
  end
end

app = Serrano::Application.new
app.get "/users", UsersController, :index

run app
```

2. Run:

```bash
bundle exec rackup
```

3. Test:

```bash
curl http://localhost:9292/users
```

---

## Controller Return Contract (IMPORTANT)

Controllers may return:

- `Hash` -> `200` with `application/json`
- `String` -> `200` with `text/plain`
- `Serrano::Response` -> respected as-is (`status`, `headers`, `body`)
- Raise `StandardError` -> `500` with JSON error body

Examples:

```ruby
def hash_case(_request)
  { ok: true }
end
```

```ruby
def string_case(_request)
  "hello"
end
```

```ruby
def custom_response(_request)
  Serrano::Response.new(
    status: 201,
    headers: { "content-type" => "application/json" },
    body: '{"created":true}'
  )
end
```

```ruby
def error_case(_request)
  raise "boom"
end
```

This contract is deterministic and intentionally minimal: each controller result maps to a single normalized HTTP behavior.

---

## Routing & HTTP Behavior

Runtime DSL:

```ruby
app.get "/users", UsersController, :index
app.post "/users", UsersController, :create
```

Static route:

```ruby
app.get "/users", UsersController, :index
```

Dynamic route parameter:

```ruby
app.get "/users/:id", UsersController, :show
```

Parameter access in controllers:

```ruby
request.params["id"]
request["id"]
```

Behavior:

- Unknown path -> `404` JSON: `{"error":"Not Found"}`
- Known path with unsupported method -> `405` JSON: `{"error":"Method Not Allowed"}`
- `405` responses include lowercase `allow` header with allowed methods

---

## Error Handling

Exceptions raised during controller execution are handled at dispatcher level.

Serrano returns:

- Status `500`
- JSON body `{"error":"Internal Server Error"}`

No stack trace is exposed in the HTTP response. This is intentional for safety.

---

## Productivity Layer (Phase 2)

Serrano includes an optional CLI scaffolding layer built with Thor. The CLI depends on core; core runtime does not depend on Thor.

Entry points:

- `bin/serrano`
- `lib/serrano/cli/base.rb`
- `lib/serrano/cli/generate.rb`
- `lib/serrano/cli/templates/*`

Available generation commands:

```bash
bundle exec ruby bin/serrano generate resource Article title:string content:text
bundle exec ruby bin/serrano generate controller Name
bundle exec ruby bin/serrano generate service Namespace::Name
bundle exec ruby bin/serrano generate repository Name
```

`generate resource` creates:

- controller
- services (`create`, `update`, `destroy`)
- repository
- entity
- migration with timestamp

Route handling remains explicit: the generator prints route snippets as suggestions and does not modify `config.ru`.

---

## Example App (`examples/basic_app`)

The example app validates architecture and flow outside framework core:

`controllers -> services -> repositories -> sequel/db`

Setup and run:

```bash
cd examples/basic_app
bundle install
bundle exec sequel -m db/migrations sqlite://db/development.sqlite3
bundle exec rackup
```

Verification:

```bash
curl -i http://localhost:9292/users
curl -i -X POST "http://localhost:9292/articles" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-raw "title=My%20Article&content=Hello"
curl -i -X POST "http://localhost:9292/articles" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-raw "content=Missing%20title"
```

Expected:

- `GET /users` -> `200`
- `POST /articles` with title -> `201`
- `POST /articles` without title -> `422` (`{"errors":["title is required"]}`)

---

## Current Scope

Serrano currently does not include:

- No ORM in framework core
- No built-in middleware stack
- No autoloading
- No dependency injection container

Notes:

- Core runtime has no generators; optional CLI layer provides scaffolding.
- Example app uses Sequel externally; ORM/database concerns are not built into core.
- Application architecture (services, repositories, domain layering, etc.) remains external to framework runtime.

---

## Project Structure

Core runtime:

```text
lib/serrano/
  application.rb
  router.rb
  request.rb
  response.rb
  dispatcher.rb
```

CLI scaffolding layer:

```text
bin/serrano
lib/serrano/cli/
  base.rb
  generate.rb
  templates/
```

Example app:

```text
examples/basic_app/
  config.ru
  config/db.rb
  app/controllers/
  app/services/
  app/repositories/
  app/entities/
  db/migrations/
```

Tests:

- `test/core` for core-level behavior
- `test/unknown_route_test.rb` for additional route invariant checks

---

## Running Core Tests

Core tests are under `test/core` and use `Rack::MockRequest` to exercise the framework without depending on the example app.

Run:

```bash
ruby test/core/http_core_test.rb
```

---

## Version

Current version: `0.1.0`  
Ruby requirement: `>= 3.2`
