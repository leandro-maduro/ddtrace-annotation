# frozen_string_literal: true

require "ddtrace/annotation/errors/invalid_proc"
require "ddtrace/annotation/tracer"

module Datadog
  module Annotation
    # Adds tracer to annotated methods
    module Decorator
      # Adds method to list of traced methods
      # @param method [Symbol] name of the method to be traced
      # @param service [String] the service name for span
      # @param resource [String || Proc] the resource in which the current span refers
      # @param metadata_proc [Proc] Block which sets tags into current trace.
      #   It receives original args, result of the traced method and span
      # @see Datadog::Annotation::Tracer.trace
      def __trace(method:, service:, resource: "#{self}##{method}", metadata_proc: nil)
        return unless datadog_enabled?

        validate_metadata_proc!(metadata_proc)

        @traced_methods[method.to_sym] = {
          service: service,
          resource: resource,
          metadata_proc: metadata_proc,
          defined?: false
        }
      end

      def method_added(name)
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

      private

      def datadog_enabled?
        Datadog.respond_to?(:tracer) && Datadog.tracer.enabled
      end

      def validate_metadata_proc!(metadata_proc)
        return if metadata_proc.nil?

        raise Errors::InvalidProc, "MetadataProc must be a Proc" unless metadata_proc.is_a?(Proc)
      end
    end
  end
end
