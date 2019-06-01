require "spec_helper"

RSpec.describe Datadog::Annotation do
  describe ".__trace" do
    let(:ddtracer) { double(:ddtracer, enabled: enabled?) }
    let(:enabled?) { true }

    before do
      allow(Datadog::Annotation::Tracer).to receive(:trace) { true }
      Datadog.define_singleton_method(:tracer) { nil }
      allow(Datadog).to receive(:respond_to?).with(:tracer) { true }
      allow(Datadog).to receive(:tracer) { ddtracer }

      eval <<-OBJECT
        class DatadogAnnotationTest
          include Datadog::Annotation

          __trace method: :test, service: "test"
          __trace method: "test2", service: "test"

          def test(a, b); end
          def test2; end
          def test3; end
        end
      OBJECT
    end

    it "adds method to list of traced methods" do
      expect(DatadogAnnotationTest.instance_variable_get(:@traced_methods)).to have_key(:test)
      expect(DatadogAnnotationTest.instance_variable_get(:@traced_methods)).to have_key(:test2)
      expect(DatadogAnnotationTest.instance_variable_get(:@traced_methods)).not_to have_key(:test3)
    end

    it "wraps method with Datadog tracer" do
      expect(Datadog::Annotation::Tracer).to receive(:trace).once.with(
        method: instance_of(Method),
        trace_info: {
          service: "test",
          resource: "DatadogAnnotationTest#test",
          metadata_proc: nil,
          defined?: true
        },
        args: [1, 2]
      )
      expect(Datadog::Annotation::Tracer).to receive(:trace).once.with(
        method: instance_of(Method),
        trace_info: {
          service: "test",
          resource: "DatadogAnnotationTest#test2",
          metadata_proc: nil,
          defined?: true
        },
        args: []
      )

      klass = DatadogAnnotationTest.new
      klass.test(1, 2)
      klass.test2
      klass.test3
    end

    context "when tracer is disabled" do
      let(:enabled?) { false }

      it "ignores instrumentation" do
        expect(DatadogAnnotationTest.instance_variable_get(:@traced_methods)).not_to have_key(:test)
        expect(DatadogAnnotationTest.instance_variable_get(:@traced_methods)).not_to have_key(:test2)
        expect(DatadogAnnotationTest.instance_variable_get(:@traced_methods)).not_to have_key(:test3)
        expect(Datadog::Annotation::Tracer).not_to receive(:trace)

        DatadogAnnotationTest.new.test(1, 2)
      end
    end

    context "when metadata_proc is not a Proc" do
      it "raises InvalidProc" do
        expect do
          eval <<-OBJECT
            class DatadogAnnotationProcTest
              include Datadog::Annotation

              __trace(
                method: :test,
                service: "test",
                metadata_proc: "test"
              )

              def test(a, b); end
            end
          OBJECT
        end.to raise_error(Datadog::Annotation::Errors::InvalidProc)
      end
    end
  end
end
