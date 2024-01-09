RSpec.describe Control::ModelStatus do

  describe Control::ModelStatus::Run do

    let(:context) do
      Chouette.create do
        referential do
          route
        end
      end
    end

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

    let(:expected_message) do
      an_object_having_attributes({
        source: source,
        criticity: "warning",
        message_attributes: {
          "name" => source.name,
          "expected_status" => I18n.t("enumerize.expected_status.#{expected_status}")
        },
        message_key: "model_status"
      })
    end

    before { referential.switch }

    describe "on StopArea" do

      let(:target_model) { "StopArea" }
      let(:stop_area) { context.route.stop_areas.first }
      let(:source) { stop_area }


      describe "enabled" do
        let(:expected_status) { 'enabled' }

        context 'search stop areas with deleted_at is nil' do
          it 'should not create a warning message' do
            control_run.run

            expect(control_run.control_messages).to be_empty
          end
        end

        context "search stop areas with deleted_at is not nil" do
          before { stop_area.update deleted_at: Date.current }

          it "should create a warning message" do
            control_run.run

            expect(control_run.control_messages).to include(expected_message)
          end
        end
      end

      describe "disabled" do
        let(:expected_status) { 'disabled' }

        context 'search stop areas with deleted_at is nil and confirmed_at is nil' do
          before { stop_area.update deleted_at: nil, confirmed_at: nil }

          it 'should not create a warning message' do
            control_run.run

            expect(control_run.control_messages).to be_empty
          end
        end

        context 'search stop areas with deleted_at is not nil and confirmed_at is nil' do
          before { stop_area.update deleted_at: DateTime.now, confirmed_at: nil }

          it 'should not create a warning message' do
            control_run.run

            expect(control_run.control_messages).to be_empty
          end
        end

        context 'search stop areas with deleted_at is nil and confirmed_at is not nil' do
          before { stop_area.update  deleted_at: nil, confirmed_at: DateTime.now }

          it "should create a warning message" do
            control_run.run

            expect(control_run.control_messages).to include(expected_message)
          end
        end

        context 'search stop areas with deleted_at is not nil and confirmed_at is not nil' do
          before { stop_area.update deleted_at: DateTime.now, confirmed_at: DateTime.now }

          it 'should not create a warning message' do
            control_run.run

            expect(control_run.control_messages).to be_empty
          end
        end
      end
    end

    describe "on Line" do
      let(:target_model) { "Line" }
      let(:line) { referential.lines.first }
      let(:source) { line }

      describe "enabled" do
        let(:expected_status) { 'enabled' }

        context 'search line with deactivated to false' do
          before { line.update deactivated: false }

          it 'should not create a warning message' do
            control_run.run

            expect(control_run.control_messages).to be_empty
          end
        end

        context "search line with deactivated to true" do
          before { line.update deactivated: true }

          it "should create a warning message" do
            control_run.run

            expect(control_run.control_messages).to include(expected_message)
          end
        end
      end

      describe "disabled" do
        let(:expected_status) { 'disabled' }

       context "search lines with deactivated to false" do
          before { line.update deactivated: false }

          it "should create a warning message" do
            control_run.run

            expect(control_run.control_messages).to include(expected_message)
          end
        end

        context 'search line with deactivated to true' do
          before { line.update deactivated: true }

          it 'should not create a warning message' do
            control_run.run

            expect(control_run.control_messages).to be_empty
          end
        end
      end
    end

  end
end
