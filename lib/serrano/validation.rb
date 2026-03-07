# frozen_string_literal: true

module Serrano
  module Validation
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def validations
        @validations ||= Hash.new { |hash, key| hash[key] = [] }
      end

      def validates(field, rules = {})
        validations[field.to_sym] << rules
      end

      def validate(input)
        attrs = symbolize_keys(input || {})
        errors = []

        validations.each do |field, field_rules|
          value = attrs[field]
          field_rules.each do |rules|
            validate_presence(field, value, rules, errors)
            validate_length(field, value, rules, errors)
            validate_format(field, value, rules, errors)
            validate_inclusion(field, value, rules, errors)
            validate_exclusion(field, value, rules, errors)
            validate_numericality(field, value, rules, errors)
            validate_range(field, value, rules, errors)
          end
        end

        if errors.empty?
          { ok: true, attrs: attrs }
        else
          { ok: false, errors: errors, attrs: attrs }
        end
      end

      private

      def symbolize_keys(input)
        input.each_with_object({}) { |(key, value), memo| memo[key.to_sym] = value }
      end

      def blank?(value)
        value.nil? || value.to_s.strip.empty?
      end

      def validate_presence(field, value, rules, errors)
        return unless rules[:presence]

        errors << "#{field} is required" if blank?(value)
      end

      def validate_length(field, value, rules, errors)
        config = rules[:length]
        return unless config
        return if blank?(value)

        str = value.to_s
        if config[:min] && str.length < config[:min]
          errors << "#{field} is too short (minimum is #{config[:min]})"
        end
        if config[:max] && str.length > config[:max]
          errors << "#{field} is too long (maximum is #{config[:max]})"
        end
      end

      def validate_format(field, value, rules, errors)
        pattern = rules[:format]
        return unless pattern
        return if blank?(value)

        errors << "#{field} is invalid" unless pattern.match?(value.to_s)
      end

      def validate_inclusion(field, value, rules, errors)
        allowed = rules[:inclusion]
        return unless allowed
        return if blank?(value)

        errors << "#{field} is not included in the list" unless allowed.include?(value)
      end

      def validate_exclusion(field, value, rules, errors)
        blocked = rules[:exclusion]
        return unless blocked
        return if blank?(value)

        errors << "#{field} is reserved" if blocked.include?(value)
      end

      def validate_numericality(field, value, rules, errors)
        config = rules[:numericality]
        return unless config
        return if blank?(value)

        number = begin
          Float(value)
        rescue StandardError
          nil
        end

        if number.nil?
          errors << "#{field} is not a number"
          return
        end

        if config.is_a?(Hash) && config[:only_integer] && number != number.to_i
          errors << "#{field} must be an integer"
        end
      end

      def validate_range(field, value, rules, errors)
        config = rules[:range]
        return unless config
        return if blank?(value)

        number = begin
          Float(value)
        rescue StandardError
          nil
        end
        return if number.nil?

        if config[:min] && number < config[:min]
          errors << "#{field} must be greater than or equal to #{config[:min]}"
        end
        if config[:max] && number > config[:max]
          errors << "#{field} must be less than or equal to #{config[:max]}"
        end
      end
    end
  end
end
