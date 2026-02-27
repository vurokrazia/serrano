# frozen_string_literal: true

require "erb"
require "fileutils"
require "thor"

module Serrano
  module CLI
    class Generate < Thor
      desc "resource NAME [fields...]", "Generate controller, services, repository, entity and migration"
      def resource(name, *fields)
        resource = resource_info(name)
        context = template_context(resource: resource)

        write_template("controller.rb.tt", target_path("app/controllers/#{resource[:plural_snake]}_controller.rb"), context)
        write_template("service_create.rb.tt", target_path("app/services/#{resource[:plural_snake]}/create.rb"), context)
        write_template("service_update.rb.tt", target_path("app/services/#{resource[:plural_snake]}/update.rb"), context)
        write_template("service_destroy.rb.tt", target_path("app/services/#{resource[:plural_snake]}/destroy.rb"), context)
        write_template("repository.rb.tt", target_path("app/repositories/#{resource[:singular_snake]}_repository.rb"), context)
        write_template("entity.rb.tt", target_path("app/entities/#{resource[:singular_snake]}.rb"), context)
        write_migration(resource, fields)

        puts "Suggested routes (add manually to config.ru):"
        puts "app.post \"/#{resource[:plural_snake]}\", #{resource[:plural_camel]}Controller, :create"
        puts "app.post \"/#{resource[:plural_snake]}/:id/update\", #{resource[:plural_camel]}Controller, :update"
        puts "app.post \"/#{resource[:plural_snake]}/:id/destroy\", #{resource[:plural_camel]}Controller, :destroy"
      end

      desc "controller NAME", "Generate a controller"
      def controller(name)
        resource = resource_info(name)
        context = template_context(resource: resource)
        write_template("controller.rb.tt", target_path("app/controllers/#{resource[:plural_snake]}_controller.rb"), context)
      end

      desc "service NAMESPACE::NAME", "Generate a service"
      def service(name)
        parts = name.split("::")
        service_name = underscore(parts.pop)
        namespace_path = parts.map { |part| underscore(part) }
        module_path = parts.map { |part| camelize(part) }
        full_dir = ["app/services", *namespace_path]
        target = target_path(File.join(*full_dir, "#{service_name}.rb"))

        write_template(
          "service_generic.rb.tt",
          target,
          template_context(
            module_path: module_path,
            service_class_name: camelize(service_name)
          )
        )
      end

      desc "repository NAME", "Generate a repository"
      def repository(name)
        singular = underscore(name).sub(/s\z/, "")
        write_template(
          "repository.rb.tt",
          target_path("app/repositories/#{singular}_repository.rb"),
          template_context(resource: resource_info(name))
        )
      end

      private

      def target_path(relative_path)
        File.expand_path(relative_path, Dir.pwd)
      end

      def template_root
        File.expand_path("templates", __dir__)
      end

      def write_template(template_name, destination, context)
        if File.exist?(destination)
          puts "skip  #{destination} (already exists)"
          return
        end

        FileUtils.mkdir_p(File.dirname(destination))
        template = File.read(File.join(template_root, template_name))
        rendered = ERB.new(template, trim_mode: "-").result_with_hash(context)
        File.write(destination, rendered)
        puts "create #{destination}"
      end

      def write_migration(resource, fields)
        timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        destination = target_path("db/migrations/#{timestamp}_create_#{resource[:plural_snake]}.rb")

        field_rows = fields.map do |field|
          name, type = field.split(":", 2)
          next if name.to_s.empty? || type.to_s.empty?

          { name: name, ruby_type: migration_type(type) }
        end.compact

        write_template(
          "migration.rb.tt",
          destination,
          template_context(resource: resource, fields: field_rows)
        )
      end

      def migration_type(type)
        case type
        when "string" then "String"
        when "text" then "String"
        when "integer" then "Integer"
        when "datetime" then "DateTime"
        else "String"
        end
      end

      def template_context(values = {})
        values
      end

      def resource_info(name)
        singular_snake = underscore(name).sub(/s\z/, "")
        plural_snake = pluralize(singular_snake)

        {
          singular_snake: singular_snake,
          plural_snake: plural_snake,
          singular_camel: camelize(singular_snake),
          plural_camel: camelize(plural_snake)
        }
      end

      def underscore(value)
        value
          .to_s
          .gsub(/::/, "/")
          .gsub(/([A-Z]+)([A-Z][a-z])/, "\\1_\\2")
          .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
          .tr("-", "_")
          .downcase
      end

      def camelize(value)
        value.to_s.split("_").map(&:capitalize).join
      end

      def pluralize(word)
        return word if word.end_with?("s")

        "#{word}s"
      end
    end
  end
end
