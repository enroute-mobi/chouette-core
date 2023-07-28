RSpec.describe Control::PresenceCustomField do

  describe Control::PresenceCustomField::Run do

    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:control_run) do
      Control::PresenceCustomField::Run.create(
        control_list_run: control_list_run,
        criticity: "warning",
        options: { target_model: target_model, target_custom_field_id: target_custom_field.id },
        position: 0
      )
    end

    subject { control_run.run }

    let(:expected_message) do
      an_object_having_attributes({
        source: source,
        message_key: "presence_custom_field",
        criticity: "warning",
        message_attributes: {
          "name"=> source.name,
          "custom_field" => target_custom_field.code,
        }
      })
    end

    describe "#Company" do
      let!(:context) do
        Chouette.create do
          custom_field code: 'public_name', resource_type: 'Company'
          company
          referential
        end
      end

      let(:company) { context.company }
      let(:target_model) { "Company" }
      let(:target_custom_field) { context.custom_field }
      let(:source) { company }
      let(:line) { context.referential.lines.first }

      before :each do
        line.update company: company
      end

      context "when a Company has no custom field value" do

        before { company.update custom_field_values: { public_name: nil } }

        it "should create a warning message" do
          subject

          expect(control_run.control_messages).to include(expected_message)
        end
      end

      context "when a Company has custom field value" do

        before { company.update custom_field_values: { public_name: "TEST" } }

        it "should have no warning message created" do
          subject

          expect(control_run.control_messages).to be_empty
        end
      end
    end

    describe "#StopArea" do
      let!(:context) do
        Chouette.create do
          custom_field code: 'public_name', resource_type: 'StopArea'
          stop_area :departure
          stop_area :arrival
          referential do
            route stop_areas: [:departure, :arrival]
          end
        end
      end

      let(:departure) { context.stop_area(:departure) }
      let(:arrival) { context.stop_area(:arrival) }
      let(:target_model) { "StopArea" }
      let(:target_custom_field) { context.custom_field }
      let(:source) { departure }

      before { context.referential.switch }

      context "when a StopArea has no custom field value" do

        before { departure.update custom_field_values: { public_name: nil } }
        before { arrival.update custom_field_values: { } }

        it "should create a warning message" do
          subject

          expect(control_run.control_messages).to include(expected_message)
        end
      end

      context "when a StopArea has custom field value" do

        before { departure.update custom_field_values: { public_name: "TEST" } }
        before { arrival.update custom_field_values: { public_name: "TEST" } }

        it "should have no warning message created" do
          subject

          expect(control_run.control_messages).to be_empty
        end
      end
    end

  end
end
