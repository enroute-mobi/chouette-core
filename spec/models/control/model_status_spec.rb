RSpec.describe Control::ModelStatus do

  describe Control::ModelStatus::Run do

    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:control_run) do
      Control::ModelStatus::Run.create(
        control_list_run: control_list_run,
        criticity: "warning",
        options: { target_model: target_model, expected_status: expected_status },
        position: 0
      )
    end

    let(:referential) { context.referential }
    subject { control_run.run }

    let(:expected_message) do
      an_object_having_attributes({
        source: source,
        criticity: "warning",
        message_attributes: {
          "name" => source.name,
        },
        message_key: "model_status"
      })
    end

    before { referential.switch }

    describe "#StopArea" do

      let(:target_model) { "StopArea" }
      let(:stop_area) { context.stop_area }
      let(:source) { stop_area }

      let(:context) do
        Chouette.create do
          stop_area
          referential
        end
      end

      describe "#enabled" do
        let(:expected_status) { 'enabled' }

        context "deleted_at is not nil" do
          before { stop_area.update deleted_at: DateTime.now }

          it "should create a warning message" do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end
      end

      describe "#disabled" do
        let(:expected_status) { 'disabled' }

        context "confirmed_at is not nil" do
          before { stop_area.update confirmed_at: DateTime.now }

          it "should create a warning message" do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end
      end
    end

    describe "#Line" do
      let(:target_model) { "Line" }
      let(:line) { referential.lines.first }
      let(:source) { line }

      let(:context) do
        Chouette.create do
          referential
        end
      end

      before do
        referential.switch
      end

      describe "#enabled" do
        let(:expected_status) { 'enabled' }

        context "when deactivated is true" do
          before { line.update deactivated: true }

          it "should create a warning message" do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end

        context "when the line is no longer activated" do
          before { line.update active_until: '2021-01-01'.to_date }

          it "should create a warning message" do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end

        context "when the line is not yet activated" do
          before { line.update active_from: '3000-01-01'.to_date,  active_until: '3000-02-02'.to_date}

          it "should create a warning message" do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end
      end

      describe "#disabled" do
        let(:expected_status) { 'disabled' }

        context "when current date is between from and until" do
          before { line.update active_from: '2021-01-01'.to_date,  active_until: '3000-01-01'.to_date}

          it "should create a warning message" do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end

        context "when current date is < until" do
          before { line.update active_from: nil,  active_until: '3000-01-01'.to_date}

          it "should create a warning message" do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end

        context "when current date is > active_from and active_from is nil" do
          before { line.update active_from: '2021-01-01'.to_date,  active_until: nil }

          it "should create a warning message" do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end
      end
    end

  end
end