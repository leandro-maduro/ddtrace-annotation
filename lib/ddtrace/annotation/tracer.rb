# frozen_string_literal: true

require_relative "errors/invalid_resource"

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
      # @param args [Array]
      def self.trace(method:, trace_info:, args:, &block)
        resource = resolve_resource(trace_info[:resource], args)

        Datadog.tracer.trace(resource, service: trace_info[:service]) do |_span|
          method.call(*args, &block)
        end
      end

      def self.resolve_resource(resource, args)
        raise Errors::InvalidResource, "Can't be empty" if resource.to_s.empty?
        return resource unless resource.is_a?(Proc)

        resource.call(*args)
      end
    end
  end
end
