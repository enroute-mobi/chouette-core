RSpec.describe Operation do

  class self::Test < Operation
    attr_accessor :id, :workgroup, :error_uuid, :status, :user_status, :started_at, :ended_at, :creator

    def persisted=(persisted)
      self.id = persisted ? Kernel.rand(10000) : nil
    end

    def persisted?
      id.present?
    end

    def update_columns(attributes)
      self.attributes = attributes
    end

    def perform_logic(&block)
      @perform_logic = block
    end
    def perform
      @perform_logic.call
    end

    def self.load_schema
      # Nothing
      @columns_hash = {}
    end
  end

  subject(:operation) { self.class::Test.new }

  it { is_expected.to enumerize(:status).in(:new, :enqueued, :running, :done).with_default(:new).with_scope(true)}
  it { is_expected.to enumerize(:user_status).in(:pending, :successful, :warning, :failed).with_default(:pending).with_scope(true) }

  describe "#perform" do
    context "when perform experiences no error" do
      before { operation.perform_logic { } }

      it "leaves error uuid undefined" do
        expect { operation.perform }.to_not change(operation, :error_uuid).from(nil)
      end

      it "changes user status from pending to successful" do
        expect { operation.perform }.to change(operation, :user_status).from(Operation.user_status.pending).to(Operation.user_status.successful)
      end
    end

    context "when perform experiences an error" do
      before { operation.perform_logic { raise "Error" } }

      it "doesn't raise the error outside" do
        expect { operation.perform }.to_not raise_error
      end

      it "defines an error uuid" do
        expect { operation.perform }.to change(operation, :error_uuid).from(nil).to(a_string_matching(/^[0-9a-f]{8}\b-[0-9a-f]{4}\b-[0-9a-f]{4}\b-[0-9a-f]{4}\b-[0-9a-f]{12}$/))
      end

      it "changes user status from pending to failed" do
        expect { operation.perform }.to change(operation, :user_status).from(Operation.user_status.pending).to(Operation.user_status.failed)
      end
    end

    context "when operation is already done" do
      before do
        operation.status = Operation.status.done
        operation.perform_logic { raise "Already done" }
      end

      it "leaves the status unchanged" do
        expect { operation.perform }.to_not change(operation, :status).from(Operation.status.done)
      end

      it "doesn't execute the perform logic" do
        expect { operation.perform }.to_not change(operation, :error_uuid).from(nil)
      end
    end
  end

  describe "#user" do
    context "when a User is associated to the Operation" do
      let(:user) { User.new name: "User Sample" }
      before { operation.user = user }

      it "defines #creator with User name" do
        is_expected.to have_attributes(creator: user.name)
      end

      it "keeps the User instance as #user attributes" do
        is_expected.to have_attributes(user: user)
      end
    end
  end

  describe "#enqueue" do

    context "when Operation isn't persisted" do
      before { operation.persisted = false }
      it { expect { operation.enqueue }.to raise_error(Operation::NotPersistedError) }
    end

    context "when Operation is persisted" do
      before do
        operation.persisted = true
        allow(Delayed::Job).to receive(:enqueue)
      end

      context "when Operation isn't new" do
        before { operation.status = Operation.status.done }
        it { expect { operation.enqueue }.to raise_error(Operation::InvalidStatusError) }
      end

      let(:job) { double }
      before { allow(operation).to receive(:job).and_return(job) }

      it "enqueues a Job to perform this Operation" do
        expect(Delayed::Job).to receive(:enqueue).with(job)
        operation.enqueue
      end

      it "changes the status to enqueued" do
        expect { operation.enqueue }.to change(operation, :status).from(Operation.status.new).to(Operation.status.enqueued)
      end
    end
  end

  describe "#job" do
    subject { operation.job }

    context "if Operation is not persisted" do
      before { operation.persisted = false }
      it { is_expected.to be_nil }
    end

    context "if Operation is persisted" do
      before { operation.persisted = true }

      it { is_expected.to be_a(Operation::Job) }

      it "has the Operation id" do
        is_expected.to have_attributes(operation_id: operation.id)
      end

      it "has the Operation class name" do
        is_expected.to have_attributes(operation_class: operation.class)
      end
    end
  end

  describe "#logger" do
    subject { operation.logger }

    it { is_expected.to be_a(Logger) }
  end

  describe "#final_user_status" do
    subject { operation.final_user_status }
    it { is_expected.to eq(Operation.user_status.successful) }
  end

  describe "#change_status" do
    context "when the given status is enqueued" do
      subject { operation.change_status(Operation.status.enqueued) }
      it "changes the Operation status to enqueued" do
        expect { subject }.to change(operation, :status).to(Operation.status.enqueued)
      end
    end

    context "when the given status is running" do
      subject { operation.change_status(Operation.status.running) }
      it "changes the Operation status to running" do
        expect { subject }.to change(operation, :status).to(Operation.status.running)
      end

      it "changes the Operation started_at to now" do
        allow(Time.zone).to receive(:now).and_return(double)
        expect { subject }.to change(operation, :started_at).from(nil).to(Time.zone.now)
      end
    end

    context "when the given status is done" do
      subject { operation.change_status(Operation.status.done) }
      it "changes the Operation status to done" do
        expect { subject }.to change(operation, :status).to(Operation.status.done)
      end

      it "changes the Operation ended_at to now" do
        allow(Time.zone).to receive(:now).and_return(double)
        expect { subject }.to change(operation, :ended_at).from(nil).to(Time.zone.now)
      end

      it "changes the Operation user status to #final_user_status" do
        allow(operation).to receive(:final_user_status).and_return(Operation.user_status.failed)
        expect { subject }.to change(operation, :user_status).to(operation.final_user_status)
      end

      context "error_uuid is defined" do
        before { operation.error_uuid = "uuid" }

        it "changes the Operation user status to failed" do
          expect { subject }.to change(operation, :user_status).to(Operation.user_status.failed)
        end
      end
    end
  end
end

RSpec.describe Operation::Callback do
  let(:operation) { double }

  subject(:callback) { Operation::Callback.new(operation) }

  describe "#before" do
    subject { callback.before }
    it { is_expected.to be_truthy }
  end

  describe "#after" do
    subject { callback.after }
    it { is_expected.to be_nil }
  end

  describe "#around" do
    it "invokes #before" do
      expect(callback).to receive(:before).and_return(true)
      callback.around {}
    end

    it "invokes #after" do
      expect(callback).to receive(:after)
      callback.around {}
    end

    it "returns the value returned by the block" do
      returned_value = 42
      expect(callback.around { returned_value }).to eq(returned_value)
    end

    context "when #before returns false" do
      before { expect(callback).to receive(:before).and_return(false) }

      it "doesn't invoke the block" do
        expect { callback.around { raise "Error" } }.to_not raise_error
      end

      it "doesn't invoke #after" do
        expect(callback).to_not receive(:after)
        expect(callback.around { })
      end
    end
  end
end

RSpec.describe Operation::Callback::Invoker do

  class self::Test < Operation::Callback
    def initialize(&block)
      super nil
      @before_logic = block
    end

    def before
      @before_logic.call
    end
  end

  def test_callback(&block)
    self::class::Test.new(&block)
  end

  subject(:invocation_order) { [] }

  it "invokes every Callback in the given order" do
    callbacks = (1..10).map do |n|
      test_callback { invocation_order << n }
    end

    Operation::Callback::Invoker.new(callbacks) {}.call

    is_expected.to eq((1..10).to_a)
  end

  it "invokes the given block after all Callbacks" do
    callbacks = [
      test_callback { invocation_order << :callback }
    ]

    Operation::Callback::Invoker.new(callbacks) do
      invocation_order << :final_proc
    end.call

    is_expected.to eq(%i{callback final_proc})
  end

  it "stops if a Callback #before return false" do
    callbacks = [
      test_callback { invocation_order << :first },
      test_callback { false },
      test_callback { invocation_order << :cancelled }
    ]

    Operation::Callback::Invoker.new(callbacks) do
      invocation_order << :final_proc
    end.call

    is_expected.to eq(%i{first})
  end

end

RSpec.describe Operation::CustomFieldLoader do

  subject(:callback) { described_class.new(operation) }
  let(:operation) { double workgroup: workgroup }
  let(:workgroup) { double }

  describe "#around" do
    it "invokes the given block by changing current workgroup (CustomFieldsSupport.within_workgroup)" do
      expect(callback.around { CustomFieldsSupport.current_workgroup }).to eq(workgroup)
    end
  end
end

RSpec.describe Operation::LogTagger do

  subject(:callback) { described_class.new(operation) }
  let(:operation) { double internal_description: "internal_description", logger: logger }

  let(:logger_output) { StringIO.new }
  let(:logger) { ActiveSupport::TaggedLogging.new(Logger.new(logger_output)) }

  describe "#around" do
    it "invokes the given block by tagging Operation logger with internal description" do
      callback.around { callback.logger.info "test" }
      expect(logger_output.string).to eq("[internal_description] test\n")
    end
  end
end

RSpec.describe Operation::PerformedSkipper do
  subject(:callback) { described_class.new(operation) }
  let(:operation) { double status: status, logger: double(warn: true) }

  describe "#before" do
    subject { callback.before }

    [ Operation.status.running, Operation.status.done ].each do |skipped|
      context "when Operation status is #{skipped}" do
        let(:status) { skipped }
        it { is_expected.to be_falsy }
      end
    end

    [ Operation.status.new, Operation.status.enqueued ].each do |compatible|
      context "when Operation status is #{compatible}" do
        let(:status) { compatible }
        it { is_expected.to be_truthy }
      end
    end
  end
end

RSpec.describe Operation::Benchmarker do
  subject(:callback) { described_class.new(operation) }
  let(:operation) { double class: "Test", id: 42 }

  describe "#around" do
    it "invokes the given block by measuring it (with Chouette::Benchmark)" do
      expect(Chouette::Benchmark).to receive(:measure).with("Test", id: 42).and_call_original
      callback.around {}
    end
  end
end

RSpec.describe Operation::StatusChanger do
  subject(:callback) { described_class.new(operation) }
  let(:operation) { double error_uuid: error_uuid }
  let(:error_uuid) { nil }

  describe "#before" do
    it "changes Operation status to running" do
      expect(operation).to receive(:change_status).with(Operation.status.running)
      callback.before
    end
  end

  describe "#after" do
    it "changes Operation status to done" do
      expect(operation).to receive(:change_status).with(Operation.status.done, any_args)
      callback.after
    end

    context "when error_uuid is defined" do
      let(:error_uuid) { "uuid" }
      it "changes the status with error_uuid" do
        expect(operation).to receive(:change_status).with(Operation.status.done, error_uuid: error_uuid)
        callback.after
      end
    end
  end
end

RSpec.describe Operation::Job do
  subject(:job) { Operation::Job.new(42, operation_class_name) }
  let(:operation_class_name) { "Test" }

  it "stores Operation id" do
    is_expected.to have_attributes(operation_id: 42)
  end

  it "stores Operation Class name" do
    is_expected.to have_attributes(operation_class_name: operation_class_name)
  end

  describe "#internal_description" do
    subject { job.internal_description }

    context "when Operation Class is Test and identifier is 42" do
      before do
        allow(job).to receive(:operation_class_name).and_return("Test")
        allow(job).to receive(:operation_id).and_return(42)
      end

      it { is_expected.to eq("Test(id=42)") }
    end
  end

  describe "#explain" do
    subject { job.explain }

    before { allow(job).to receive(:internal_description).and_return("internal_description") }

    it "returns the internal description" do
      is_expected.to eq(job.internal_description)
    end
  end

  describe "#operation" do
    subject { job.operation }

    let(:operation_class) { double find_by: nil }
    before { allow(job).to receive(:operation_class).and_return(operation_class) }

    it "returns nil when the Operation is not found" do
      expect(operation_class).to receive(:find_by).with(id: job.operation_id)
      is_expected.to be_nil
    end

    it "returns the Operation find by id" do
      operation = double
      expect(operation_class).to receive(:find_by).with(id: job.operation_id).and_return(operation)
      is_expected.to eq(operation)
    end
  end

  describe "#perform" do
    context "when Operation is found" do
      let(:operation) { double }
      before { allow(job).to receive(:operation).and_return(operation) }

      it "invokes the Operation #perform method" do
        expect(operation).to receive(:perform)
        job.perform
      end
    end

    context "when Operation is not found" do
      before { allow(job).to receive(:operation).and_return(nil) }

      it "doesn't raise an error" do
        expect { job.perform }.to_not raise_error
      end

      it "logs a warn message" do
        expect(job.logger).to receive(:warn)
        job.perform
      end
    end
  end

  describe "#max_attempts" do
    subject { job.max_attempts }
    it { is_expected.to eq(1) }
  end

  describe "#max_run_time" do
    subject { job.max_run_time }
    it { is_expected.to eq(Delayed::Worker.max_run_time) }
  end
end
