# frozen_string_literal: true

require "erb"
require "fileutils"
require "thor"
require_relative "generate"

module Serrano
  module CLI
    class Base < Thor
      DB_ADAPTER_GEMS = {
        "sqlite" => "sqlite3",
        "postgres" => "pg",
        "mysql" => "mysql2"
      }.freeze

      desc "new APP_NAME", "Create a new Serrano project"
      method_option :minimal, type: :boolean, default: false
      method_option :db, type: :string, enum: DB_ADAPTER_GEMS.keys, banner: "sqlite|postgres|mysql"
      def new(app_name)
        root = File.expand_path(app_name, Dir.pwd)
        template_root = File.expand_path("templates", __dir__)
        @db_adapter = options[:db]
        @app_name = app_name

        FileUtils.mkdir_p(root)
        puts "create #{root}"

        write_template(template_root, "new_project_gemfile.tt", File.join(root, "Gemfile"))
        write_template(template_root, "new_project_config.ru.tt", File.join(root, "config.ru"))
        write_template(template_root, "new_project_db.rb.tt", File.join(root, "config/db.rb")) if db_enabled?

        if options[:minimal]
          # minimal mode intentionally keeps only boot files (plus optional config/db.rb)
        else
          %w[app/controllers app/services app/repositories app/entities db/migrations].each do |relative_dir|
            dir = File.join(root, relative_dir)
            FileUtils.mkdir_p(dir)
            puts "create #{dir}"
          end
        end

        puts
        puts "Next steps:"
        puts "cd #{app_name}"
        puts "bundle install"
        puts "bundle exec rackup"
      end

      desc "generate SUBCOMMAND ...ARGS", "Generate Serrano application files"
      subcommand "generate", Generate

      private

      def write_template(template_root, template_name, destination)
        if File.exist?(destination)
          puts "skip  #{destination} (already exists)"
          return
        end

        FileUtils.mkdir_p(File.dirname(destination))
        template = File.read(File.join(template_root, template_name))
        rendered = ERB.new(template, trim_mode: "-").result(binding)
        File.write(destination, rendered)
        puts "create #{destination}"
      end

      def db_enabled?
        !@db_adapter.nil?
      end

      def db_gem_name
        DB_ADAPTER_GEMS[@db_adapter]
      end

      def config_db_require_line
        db_enabled? ? "require_relative \"config/db\"" : nil
      end

      def db_connection_url
        case @db_adapter
        when "sqlite"
          "sqlite://db/development.sqlite3"
        when "postgres"
          "postgres://localhost/#{@app_name}_development"
        when "mysql"
          "mysql2://root@localhost/#{@app_name}_development"
        end
      end
    end
  end
end
