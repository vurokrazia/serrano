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
        field_rows = parse_fields(fields)
        context = template_context(
          resource: resource,
          fields: field_rows
        )

        write_template("controller.rb.tt", target_path("app/controllers/#{resource[:plural_snake]}_controller.rb"), context)
        write_template("service_index.rb.tt", target_path("app/services/#{resource[:plural_snake]}/index.rb"), context)
        write_template("service_show.rb.tt", target_path("app/services/#{resource[:plural_snake]}/show.rb"), context)
        write_template("service_create.rb.tt", target_path("app/services/#{resource[:plural_snake]}/create.rb"), context)
        write_template("service_update.rb.tt", target_path("app/services/#{resource[:plural_snake]}/update.rb"), context)
        write_template("service_destroy.rb.tt", target_path("app/services/#{resource[:plural_snake]}/destroy.rb"), context)
        write_template("repository.rb.tt", target_path("app/repositories/#{resource[:singular_snake]}_repository.rb"), context)
        write_template("entity.rb.tt", target_path("app/entities/#{resource[:singular_snake]}.rb"), context)
        write_migration(resource, field_rows)
        inject_resource_routes(resource)

        puts "Routes ensured in config.ru:"
        puts "app.get \"/#{resource[:plural_snake]}\", #{resource[:plural_camel]}Controller, :index"
        puts "app.get \"/#{resource[:plural_snake]}/:id\", #{resource[:plural_camel]}Controller, :show"
        puts "app.post \"/#{resource[:plural_snake]}\", #{resource[:plural_camel]}Controller, :create"
        puts "app.put \"/#{resource[:plural_snake]}/:id\", #{resource[:plural_camel]}Controller, :update"
        puts "app.delete \"/#{resource[:plural_snake]}/:id\", #{resource[:plural_camel]}Controller, :destroy"
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

      def write_migration(resource, field_rows)
        timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        destination = target_path("db/migrations/#{timestamp}_create_#{resource[:plural_snake]}.rb")

        write_template(
          "migration.rb.tt",
          destination,
          template_context(resource: resource, fields: field_rows)
        )
      end

      def parse_fields(fields)
        fields.map do |field|
          parts = field.split(":")
          name = parts[0]
          type = parts[1]
          flags = parts[2..] || []
          next if name.to_s.empty? || type.to_s.empty?

          metadata = {
            name: name,
            ruby_type: migration_type(type),
            required: false,
            unique: false,
            immutable: false,
            min: nil,
            max: nil,
            format: nil,
            inclusion: nil,
            exclusion: nil,
            range_min: nil,
            range_max: nil,
            numericality: false,
            numericality_integer: type == "integer"
          }

          flags.each do |flag|
            case flag
            when "required"
              metadata[:required] = true
            when "unique"
              metadata[:unique] = true
            when "immutable"
              metadata[:immutable] = true
            when "int", "integer"
              metadata[:numericality_integer] = true
            when "num", "numeric"
              metadata[:numericality] = true
            else
              if (match = flag.match(/\Amin=(\d+)\z/))
                metadata[:min] = match[1].to_i
              elsif (match = flag.match(/\Amax=(\d+)\z/))
                metadata[:max] = match[1].to_i
              elsif (match = flag.match(/\Aformat=(.+)\z/))
                metadata[:format] = match[1]
              elsif (match = flag.match(/\Ain=(.+)\z/))
                metadata[:inclusion] = match[1].split("|")
              elsif (match = flag.match(/\Aexclude=(.+)\z/))
                metadata[:exclusion] = match[1].split("|")
              elsif (match = flag.match(/\Arange=(-?\d+)\.\.(-?\d+)\z/))
                metadata[:range_min] = match[1].to_i
                metadata[:range_max] = match[2].to_i
              end
            end
          end

          metadata[:numericality] = true if metadata[:numericality_integer]

          {
            name: metadata[:name],
            ruby_type: metadata[:ruby_type],
            required: metadata[:required],
            unique: metadata[:unique],
            immutable: metadata[:immutable],
            min: metadata[:min],
            max: metadata[:max],
            format: metadata[:format],
            inclusion: metadata[:inclusion],
            exclusion: metadata[:exclusion],
            range_min: metadata[:range_min],
            range_max: metadata[:range_max],
            numericality: metadata[:numericality],
            numericality_integer: metadata[:numericality_integer]
          }
        end.compact
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
        return "#{word[0..-2]}ies" if word.end_with?("y") && word.length > 1
        return "#{word}es" if word.end_with?("s", "x", "z") || word.end_with?("ch", "sh")

        "#{word}s"
      end

      def inject_resource_routes(resource)
        config_ru_path = target_path("config.ru")
        return unless File.exist?(config_ru_path)

        lines = File.read(config_ru_path).lines
        require_line = "require_relative \"./app/controllers/#{resource[:plural_snake]}_controller\"\n"
        route_lines = [
          "app.get \"/#{resource[:plural_snake]}\", #{resource[:plural_camel]}Controller, :index\n",
          "app.get \"/#{resource[:plural_snake]}/:id\", #{resource[:plural_camel]}Controller, :show\n",
          "app.post \"/#{resource[:plural_snake]}\", #{resource[:plural_camel]}Controller, :create\n",
          "app.put \"/#{resource[:plural_snake]}/:id\", #{resource[:plural_camel]}Controller, :update\n",
          "app.delete \"/#{resource[:plural_snake]}/:id\", #{resource[:plural_camel]}Controller, :destroy\n"
        ]

        changed = false

        unless lines.include?(require_line)
          app_decl_index = lines.index { |line| line.strip.start_with?("app = ") }
          existing_require_indexes = lines.each_index.select do |index|
            stripped = lines[index].strip
            stripped.start_with?("require ") || stripped.start_with?("require_relative ")
          end
          insert_at = if app_decl_index
                        existing_require_indexes.select { |index| index < app_decl_index }.max.to_i + 1
                      else
                        existing_require_indexes.max.to_i + 1
                      end
          lines.insert(insert_at, require_line)
          changed = true
        end

        app_decl_index = lines.index { |line| line.strip.start_with?("app = ") }
        run_index = lines.index { |line| line.strip == "run app" } || lines.length
        route_insert_index = if app_decl_index && app_decl_index < run_index
                               run_index
                             else
                               run_index
                             end
        route_lines.each do |route_line|
          next if lines.include?(route_line)

          lines.insert(route_insert_index, route_line)
          route_insert_index += 1
          changed = true
        end

        return unless changed

        File.write(config_ru_path, lines.join)
        puts "update #{config_ru_path}"
      end
    end
  end
end
