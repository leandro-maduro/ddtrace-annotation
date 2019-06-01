# frozen_string_literal: true

require "ddtrace/annotation/errors/invalid_resource"

module Datadog
  module Annotation
    # Datadog::Annotation::Tracer is responsible for setting up the trace for the annotated method
    class Tracer
      # @param method [Method]
      # @param trace_info [Hash]
      #   Ex: trace_info: {
      #     service: "web",
      #     resource: "Users#create"
      #   }
      #
      #   @option +service+: [String] the service name for span
      #   @option +resource+: [String || Proc] the resource in which the current span refers
      #
      #   If by any reason you need to use some information that your method receives
      #   as a parameter, you can set a Proc as a resource.
      #
      #     Ex:
      #       __trace(
      #         method: :test,
      #         service: "web"
      #         resource: Proc.new { |_, type| "test##{type}"}
      #       )
      #       def test(name, type); end
      #   @option +metadata_proc+: [Proc] Block which sets tags into current trace.
      #   It receives original args, result of the traced method and span
      #
      #     Ex:
      #       __trace(
      #         method: :test,
      #         service: "web"
      #         metadata_proc: Proc.new do |args, result, span|
      #           span.set_tag("name", args[:name])
      #           span.set_tag("type", args[:type])
      #           span.set_tag("result", result)
      #         end
      #       )
      #       def test(name, type); end
      # @param args [Array]
      def self.trace(method:, trace_info:, args:, &block)
        resource = resolve_resource!(trace_info[:resource], args)
        metadata_proc = trace_info[:metadata_proc]

        Datadog.tracer.trace(resource, service: trace_info[:service]) do |span|
          result = method.call(*args, &block)

          resolve_metadata!(
            metadata_proc: metadata_proc,
            method: method,
            args: args,
            result: result,
            span: span
          )

          result
        end
      end

      def self.resolve_resource!(resource, args)
        raise Errors::InvalidResource, "Can't be empty" if resource.to_s.empty?
        return resource unless resource.is_a?(Proc)

        resource.call(*args)
      end

      def self.resolve_metadata!(metadata_proc:, method:, args:, result:, span:)
        return if metadata_proc.nil?

        arguments = {}
        method.parameters.each_with_index { |parameter, index| arguments[parameter[1]] = args[index] }
        metadata_proc.call(arguments, result, span)
      end

      private_class_method :resolve_resource!, :resolve_metadata!
    end
  end
end
