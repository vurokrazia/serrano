# Serrano

Serrano is a minimal Rack-based Ruby microframework with an explicit HTTP contract and no hidden behavior.

---

## What is Serrano

Serrano provides only the HTTP runtime:

- route registration and matching (`GET`, `POST`, `PUT`, `DELETE`)
- controller dispatching
- request and response wrappers
- strict error-to-response mapping

Serrano is intentionally small. It does not include:

- an ORM
- middleware stacks
- dependency injection containers
- architecture conventions beyond thin controller/service/repository layering

If you want database or CRUD tooling, use the optional CLI and example scaffolding layer.

---

## Core Contracts

- Supported methods: `GET`, `POST`, `PUT`, `DELETE`
- Route DSL:
  - `get(path, controller, action)`
  - `post(path, controller, action)`
  - `put(path, controller, action)`
  - `delete(path, controller, action)`
- Controller return values:
  - `Hash` => JSON response, status `200`
  - `String` => `text/plain`, status `200`
  - `Serrano::Response` => use as-is
  - other values => `500` with JSON error
- Missing route => `404 Not Found`
- Missing method for existing path => `405 Method Not Allowed` with lowercase `allow` header and supported methods
- Controller exceptions => `500` JSON error response. Example: `{"error":"RuntimeError: boom"}`

See [EXAMPLES.md](./EXAMPLES.md) for full request/response demos.

---

## Installation (gem)

- Ruby `>= 3.2`
- Published gem:

  - `serrano-vk` on RubyGems (`~> 0.1.2`)

- Add to your app Gemfile:

```ruby
# Gemfile
source "https://rubygems.org"

gem 'serrano-vk', '~> 0.1.2'
```

Run:

```bash
bundle install
```

---

## Quick Start (Core only)

`config.ru`:

```ruby
# frozen_string_literal: true

require 'serrano'

class UsersController
  def index(_request)
    { users: [] }
  end
end

app = Serrano::Application.new
app.get('/users', UsersController, :index)

run app
```

Run:

```bash
bundle exec rackup
```

Quick check:

```bash
curl -i http://localhost:9292/users
```

---

## Productivity Layer (CLI)

The CLI is optional and depends on the core runtime.

### Available commands

```bash
serrano new APP_NAME [--minimal] [--db=sqlite|postgres|mysql]
serrano generate resource Article title:string content:text
serrano generate controller Name
serrano generate service Namespace::Name
serrano generate repository Name
```

- `new` creates project files (minimal mode and DB options are orthogonal)
- `generate resource` creates controller, services (`index`, `show`, `create`, `update`, `destroy`), repository, entity, migration
- route code is printed as suggestions; config.ru updates are explicit and user-managed

### Parameters in requests

Using controller params:

```bash
curl -i "http://localhost:9292/users/12?foo=abc"
curl -i -X POST "http://localhost:9292/articles" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data "title=First&content=Hello"
```

For full command usage with sample outputs and full flows, read [EXAMPLES.md](./EXAMPLES.md).

---

## Project Structure

Core runtime:

```text
lib/serrano/
  application.rb
  cli/
  dispatcher.rb
  request.rb
  response.rb
  router.rb
```

Example app (optional):

```text
app/
  controllers/
  services/
  repositories/
  entities/
config/
  db.rb
config.ru
```

---

## Testing

Core tests are isolated under:

- `test/core/*`

Run all tests:

```bash
bundle exec rake test
```

---

## Version

Current version: `0.1.2` (gem: serrano-vk)  
Ruby requirement: `>= 3.2`
