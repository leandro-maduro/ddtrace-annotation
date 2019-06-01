# frozen_string_literal: true

require "ddtrace/annotation/version"
require "ddtrace/annotation/errors/base"
require "ddtrace/annotation/decorator"

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
        extend Decorator
        @traced_methods = {}
      end
    end
  end
end
