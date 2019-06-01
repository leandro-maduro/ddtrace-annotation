require "spec_helper"

RSpec.describe Datadog::Annotation::Tracer do
  class DatadogAnnotationTracerTest
    def test(name, message); end
  end

  describe ".trace" do
    subject(:trace) { described_class.trace(method: method, trace_info: trace_info, args: args) }

    let(:ddtracer) { double(:ddtracer, trace: nil) }
    let(:span) { double(:span, set_tag: true) }
    let(:method) { DatadogAnnotationTracerTest.new.method(:test) }

    let(:args) do
      [
        "name",
        type: "type",
        content: "content"
      ]
    end

    let(:trace_info) do
      {
        service: "web",
        resource: "test"
      }
    end

    before do
      Datadog.define_singleton_method(:tracer) { nil }
      allow(Datadog).to receive(:tracer) { ddtracer }
      allow(ddtracer).to receive(:trace).and_yield(span)
    end

    it "traces method" do
      expect(ddtracer).to receive(:trace).once.with("test", service: "web")
      expect(method).to receive(:call).once.with("name", type: "type", content: "content")

      trace
    end

    context "when resource is a Proc" do
      let(:trace_info) do
        {
          service: "web",
          resource: proc { |_, message| "test##{message[:type]}" }
        }
      end

      it "resolves resource name" do
        expect(ddtracer).to receive(:trace).once.with("test#type", service: "web")

        trace
      end
    end

    context "when resource is nil" do
      let(:trace_info) do
        {
          service: "web",
          resource: nil
        }
      end

      it "uses default value" do
        expect(ddtracer).to receive(:trace).once.with("DatadogAnnotationTracerTest#test", service: "web")

        trace
      end
    end

    context "when resource is empty" do
      let(:trace_info) do
        {
          service: "web",
          resource: ""
        }
      end

      it "uses default value" do
        expect(ddtracer).to receive(:trace).once.with("DatadogAnnotationTracerTest#test", service: "web")

        trace
      end
    end
  end
end