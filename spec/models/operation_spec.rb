RSpec.describe Operation do

  class self::Test < Operation
    attr_accessor :workgroup, :error_uuid, :status, :ended_at

    def perform_logic(&block)
      @perform_logic = block
    end
    def perform
      puts "perform"
      @perform_logic.call
    end

    def self.load_schema
      # Nothing
      @columns_hash = {}
    end
  end

  subject(:operation) { self.class::Test.new }

  describe "#perform" do
    context "when perform experiences an error" do
      before { operation.perform_logic { raise "Error" } }

      it "doesn't raise the error outside" do
        expect { operation.perform }.to_not raise_error
      end

      it "defines an error uuid" do
        expect { operation.perform }.to change(operation, :error_uuid).from(nil).to(a_string_matching(/^[0-9a-f]{8}\b-[0-9a-f]{4}\b-[0-9a-f]{4}\b-[0-9a-f]{4}\b-[0-9a-f]{12}$/))
      end
    end
  end

end
