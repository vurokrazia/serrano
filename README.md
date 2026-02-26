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

## Quick Start

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

## Routing

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
- `405` responses include `allow` header with allowed methods

---

## Error Handling

Exceptions raised during controller execution are handled at dispatcher level.

Serrano returns:

- Status `500`
- JSON body `{"error":"Internal Server Error"}`

No stack trace is exposed in the HTTP response. This is intentional for safety.

---

## Current Scope

Serrano currently does not include:

- No ORM
- No built-in middleware stack
- No autoloading
- No CLI
- No generators
- No dependency injection container

Application architecture (services, repositories, domain layering, etc.) is intentionally external to the framework core.

---

## Project Structure

Framework core:

```text
lib/serrano/
  application.rb
  router.rb
  request.rb
  response.rb
  dispatcher.rb
```

Separation:

- Framework core lives in `lib/serrano/`
- Core tests live under `test/` (including `test/core`)
- Example app lives in `examples/basic_app`

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
