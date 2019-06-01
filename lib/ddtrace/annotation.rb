# frozen_string_literal: true

require "ddtrace/annotation/version"
require "ddtrace/annotation/errors/base"
require "ddtrace/annotation/tracer"

module Datadog
  # Datadog::Annotation allows you to annotate methods which you want to trace.
  # Usage:
  #   class Test
  #     include Datadog::Annotation
  #
  #     __trace method: :test, service: "web"
  #     def test; end
  module Annotation
    def self.included(base)
      base.class_eval do
        @traced_methods = {}

        def self.__trace(method:, service:, resource: "#{self}##{method}")
          return unless datadog_enabled?

          @traced_methods[method.to_sym] = {
            service: service,
            resource: resource,
            defined?: false
          }
        end

        def self.method_added(name)
          super

          return if !@traced_methods.key?(name) || @traced_methods.dig(name, :defined?)

          @traced_methods[name][:defined?] = true

          method = instance_method(name)
          trace_info = @traced_methods[name]

          define_method(name) do |*args, &block|
            Annotation::Tracer.trace(
              method: method.bind(self),
              trace_info: trace_info,
              args: args,
              &block
            )
          end
        end

        def self.datadog_enabled?
          Datadog.respond_to?(:tracer) && Datadog.tracer.enabled
        end

        private_class_method :datadog_enabled?
      end
    end
  end
end
