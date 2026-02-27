# frozen_string_literal: true

require "erb"
require "fileutils"
require "thor"
require_relative "generate"

module Serrano
  module CLI
    class Base < Thor
      desc "new APP_NAME", "Create a new Serrano project"
      method_option :minimal, type: :boolean, default: false
      def new(app_name)
        root = File.expand_path(app_name, Dir.pwd)
        template_root = File.expand_path("templates", __dir__)

        FileUtils.mkdir_p(root)
        puts "create #{root}"

        if options[:minimal]
          write_template(template_root, "new_minimal_gemfile.tt", File.join(root, "Gemfile"))
          write_template(template_root, "new_minimal_config.ru.tt", File.join(root, "config.ru"))
        else
          write_template(template_root, "new_default_gemfile.tt", File.join(root, "Gemfile"))
          write_template(template_root, "new_default_config.ru.tt", File.join(root, "config.ru"))
          write_template(template_root, "new_default_db.rb.tt", File.join(root, "config/db.rb"))

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
    end
  end
end
