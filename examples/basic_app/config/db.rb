# frozen_string_literal: true

require "sequel"

DB = Sequel.connect(
  adapter: "sqlite",
  database: File.expand_path("../db/development.sqlite3", __dir__)
)
