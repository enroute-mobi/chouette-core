RSpec.describe Control::PresenceAttribute do

  describe Control::PresenceAttribute::Run do

    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:control_run) do
      Control::PresenceAttribute::Run.create(
        control_list_run: control_list_run,
        criticity: "warning",
        options: { target_model: target_model, target_attribute: target_attribute },
        position: 0
      )
    end

    describe "#run" do
      subject { control_run.run }

      let(:context) do
        Chouette.create do
          company
          network
          line
          stop_area :first
          stop_area :middle
          stop_area :last
          shape :shape
          referential do
            route stop_areas: [:first, :middle, :last] do
              journey_pattern shape: :shape
            end
          end
        end
      end

      let(:expected_message) do
        an_object_having_attributes({
          source: source,
          message_key: message_key,
          criticity: criticity,
          message_attributes: {"attribute_name" => attribute_name}
        })
      end

      before do
        context.referential.switch
      end

      describe "JourneyPattern" do
        let(:journey_pattern) { context.journey_pattern }
        let(:target_model) { "JourneyPattern" }
        let(:target_attribute) { "shape" }
        let(:shape) { context.shape(:shape) }

        context "when shape is present" do
          let(:message_key) { "presence_of_attribute" }
          let(:criticity) { "info" }
          let(:attribute_name) { "shape"}
          let(:source) { journey_pattern }

          it "should create a info message" do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end

        context "when shape is not present" do
          before { shape.delete }

          let(:message_key) { "no_presence_of_attribute" }
          let(:criticity) { "warning" }
          let(:attribute_name) { "shape"}
          let(:source) { journey_pattern }

          it "should create a warning message" do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end
      end

      describe "Line" do
        let(:company) { context.company }
        let(:network) { context.network }
        let(:line) { context.line }
        let(:source) { line }
        let(:target_model) { "Line" }

        describe "#published_name" do
          let(:attribute_name) { "published_name"}
          let(:target_attribute) { "published_name"}

          context "when value is present" do
            before { line.update published_name: "Published Name" }

            let(:message_key) { "presence_of_attribute" }
            let(:criticity) { "info" }

            it "should create info message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context "when value is not present" do
            before { line.update published_name: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#number" do
          let(:attribute_name) { "number"}
          let(:target_model) { "Line" }
          let(:target_attribute) { "number"}

          context "when value is present" do
            before { line.update number: "number" }

            let(:message_key) { "presence_of_attribute" }
            let(:criticity) { "info" }

            it "should create info message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context "when value is not present" do
            before { line.update number: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#transport_mode" do
          let(:attribute_name) { "transport_mode"}
          let(:target_model) { "Line" }
          let(:target_attribute) { "transport_mode"}

          context "when value is present" do
            before { line.update transport_mode: "bus" }

            let(:message_key) { "presence_of_attribute" }
            let(:criticity) { "info" }

            it "should create info message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context "when value is not present" do
            before { line.update transport_mode: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#company" do
          let(:attribute_name) { "company"}
          let(:target_model) { "Line" }
          let(:target_attribute) { "company"}

          context "when value is present" do
            before { line.update company: company }

            let(:message_key) { "presence_of_attribute" }
            let(:criticity) { "info" }

            it "should create info message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context "when value is not present" do
            before { line.update company: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#network" do
          let(:attribute_name) { "network"}
          let(:target_model) { "Line" }
          let(:target_attribute) { "network"}

          context "when value is present" do
            before { line.update network: network }

            let(:message_key) { "presence_of_attribute" }
            let(:criticity) { "info" }

            it "should create info message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context "when value is not present" do
            before { line.update network: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#color" do
          let(:attribute_name) { "color"}
          let(:target_model) { "Line" }
          let(:target_attribute) { "color"}

          context "when value is present" do
            before { line.update color: "FF5733" }

            let(:message_key) { "presence_of_attribute" }
            let(:criticity) { "info" }

            it "should create info message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context "when value is not present" do
            before { line.update color: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#text_color" do
          let(:attribute_name) { "text_color"}
          let(:target_model) { "Line" }
          let(:target_attribute) { "text_color"}

          context "when value is present" do
            before { line.update text_color: "FF5733" }

            let(:message_key) { "presence_of_attribute" }
            let(:criticity) { "info" }

            it "should create info message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context "when value is not present" do
            before { line.update text_color: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end

      describe "StopArea" do
        let(:company) { context.company }
        let(:network) { context.network }
        let(:stop_area) { context.stop_area(:first).reload }
        let(:source) { stop_area }
        let(:target_model) { "StopArea" }

        describe "#public_code" do
          let(:attribute_name) { "public_code"}
          let(:target_attribute) { "public_code"}

          context "when value is present" do
            before { stop_area.update public_code: "12345" }

            let(:message_key) { "presence_of_attribute" }
            let(:criticity) { "info" }

            it "should create info message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context "when value is not present" do
            before { stop_area.update public_code: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#coordinates" do
          let(:attribute_name) { "coordinates" }
          let(:target_attribute) { "coordinates" }

          context "when value is present" do
            before { stop_area.update longitude: 0.7091187, latitude: 0.43600792}

            let(:message_key) { "presence_of_attribute" }
            let(:criticity) { "info" }

            it "should create info message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context "when value is not present" do
            before { stop_area.update longitude: nil, latitude: nil}

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end

    end
  end
end