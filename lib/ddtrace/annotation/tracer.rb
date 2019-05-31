# frozen_string_literal: true

module Datadog
  module Annotation
    class Tracer
      def self.trace(method:, trace_info:, args:, &block)
        Datadog.tracer.trace("actor.messaging.slack") do
          method.call(*args, &block)
        end
      end
    end
  end
end
