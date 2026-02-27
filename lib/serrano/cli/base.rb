# frozen_string_literal: true

require "thor"
require_relative "generate"

module Serrano
  module CLI
    class Base < Thor
      desc "generate SUBCOMMAND ...ARGS", "Generate Serrano application files"
      subcommand "generate", Generate
    end
  end
end