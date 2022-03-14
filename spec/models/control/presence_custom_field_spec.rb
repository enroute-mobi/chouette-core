RSpec.describe Control::PresenceCustomField do

  describe Control::PresenceCustomField::Run do

    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:control_run) do
      Control::PresenceCustomField::Run.create(
        control_list_run: control_list_run,
        criticity: "warning",
        options: { target_model: target_model, target_custom_field: target_custom_field },
        position: 0
      )
    end

    subject { control_run.run }

    let(:expected_message) do
      an_object_having_attributes({
        source: source,
        criticity: "warning",
        message_attributes: {"target_custom_field" => target_custom_field.to_s}
      })
    end

    describe "#Company" do
      let!(:context) do
        Chouette.create do
          company
          referential
        end
      end

      let!(:custom_field_public_name) do
        create :custom_field, field_type: :string, code: :public_name, name: "Name", workgroup: context.workgroup, resource_type: "Company"
      end

      let(:company) { context.company }
      let(:target_model) { "Company" }
      let(:target_custom_field) { :public_name }
      let(:source) { company }

      before { context.referential.switch }

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
          stop_area
          referential
        end
      end

      let!(:custom_field_public_name) do
        create :custom_field, field_type: :string, code: :public_name, name: "Name", workgroup: context.workgroup, resource_type: "StopArea"
      end

      let(:stop_area) { context.stop_area }
      let(:target_model) { "StopArea" }
      let(:target_custom_field) { :public_name }
      let(:source) { stop_area }

      before { context.referential.switch }

      context "when a StopArea has no custom field value" do

        before { stop_area.update custom_field_values: { public_name: nil } }

        it "should create a warning message" do
          subject

          expect(control_run.control_messages).to include(expected_message)
        end
      end

      context "when a StopArea has custom field value" do

        before { stop_area.update custom_field_values: { public_name: "TEST" } }

        it "should have no warning message created" do
          subject

          expect(control_run.control_messages).to be_empty
        end
      end
    end

  end
end