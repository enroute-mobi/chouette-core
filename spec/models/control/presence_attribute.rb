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

      let(:referential) { context.referential }

      let(:expected_message) do
        an_object_having_attributes({
          source: source,
          message_key: message_key,
          criticity: criticity,
          message_attributes: {"attribute_name" => attribute_name}
        })
      end

      before do
        referential.switch
      end

      describe "JourneyPattern" do
        let(:journey_pattern) { context.journey_pattern }
        let(:target_model) { "JourneyPattern" }
        let(:target_attribute) { "shape" }
        let(:shape) { context.shape(:shape) }

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
        let(:line) { referential.lines.first }
        let(:source) { line }
        let(:target_model) { "Line" }

        describe "#published_name" do
          let(:attribute_name) { "published_name"}
          let(:target_attribute) { "published_name"}

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

        describe "#url" do
          let(:attribute_name) { "url"}
          let(:target_attribute) { "url"}

          context "when value is not present" do
            before { line.update url: nil }

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
          let(:attribute_name) { "public_code" }
          let(:target_attribute) { "public_code" }

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

        describe "#url" do
          let(:attribute_name) { "url"}
          let(:target_attribute) { "url"}

          context "when value is not present" do
            before { stop_area.update url: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#parent" do
          let(:attribute_name) { "parent" }
          let(:target_attribute) { "parent" }
          let(:parent) { create(:stop_area) }

          context "when value is not present" do
            before { stop_area.update parent: nil}

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#referent" do
          let(:attribute_name) { "referent" }
          let(:target_attribute) { "referent" }

          context "when value is not present" do
            before { stop_area.update referent: nil}

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

        describe "#compass_bearing" do
          let(:attribute_name) { "compass_bearing" }
          let(:target_attribute) { "compass_bearing" }

          context "when value is not present" do
            before { stop_area.update compass_bearing: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#street_name" do
          let(:attribute_name) { "street_name" }
          let(:target_attribute) { "street_name" }

          context "when value is not present" do
            before { stop_area.update street_name: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#zip_code" do
          let(:attribute_name) { "zip_code" }
          let(:target_attribute) { "zip_code" }

          context "when value is not present" do
            before { stop_area.update zip_code: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#city_name" do
          let(:attribute_name) { "city_name" }
          let(:target_attribute) { "city_name" }

          context "when value is not present" do
            before { stop_area.update city_name: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#postal_region" do
          let(:attribute_name) { "postal_region" }
          let(:target_attribute) { "postal_region" }

          context "when value is not present" do
            before { stop_area.update postal_region: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#country" do
          let(:attribute_name) { "country" }
          let(:target_attribute) { "country" }

          context "when value is not present" do
            before { stop_area.update country_code: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#time_zone" do
          let(:attribute_name) { "time_zone" }
          let(:target_attribute) { "time_zone" }

          context "when value is not present" do
            before { stop_area.update time_zone: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#waiting_time" do
          let(:attribute_name) { "waiting_time" }
          let(:target_attribute) { "waiting_time" }

          context "when value is not present" do
            before { stop_area.update waiting_time: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#fare_code" do
          let(:attribute_name) { "fare_code" }
          let(:target_attribute) { "fare_code" }

          context "when value is not present" do
            before { stop_area.update fare_code: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end

      describe "#VehicleJourney" do
        let(:company) {context.company}
        let(:vehicle_journey) { create(:vehicle_journey) }
        let(:source) { vehicle_journey }
        let(:target_model) { "VehicleJourney" }

        describe "#transport_mode" do
          let(:attribute_name) { "transport_mode"}
          let(:target_attribute) { "transport_mode"}

          context "when value is not present" do
            before { vehicle_journey.update transport_mode: nil }

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
          let(:target_attribute) { "company"}

          context "when value is not present" do
            before { vehicle_journey.update company: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#published_journey_identifier" do
          let(:attribute_name) { "published_journey_identifier"}
          let(:target_attribute) { "published_journey_identifier"}

          context "when value is not present" do
            before { vehicle_journey.update published_journey_identifier: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#published_journey_name" do
          let(:attribute_name) { "published_journey_name"}
          let(:target_attribute) { "published_journey_name"}

          context "when value is not present" do
            before { vehicle_journey.update published_journey_name: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end

      describe "#Company" do
        let(:company) {context.company}
        let(:source) { company }
        let(:target_model) { "Company" }

        [ "short_name", "house_number", "street", "address_line_1", "address_line_2",
          "town", "postcode", "postcode_extension", "default_contact_name", "code"  ].each do |attr_name|
          describe "##{attr_name}" do
            let(:attribute_name) { attr_name}
            let(:target_attribute) { attr_name}

            context "when value is not present" do
              before { company.update({attr_name.to_sym => nil}) }

              let(:message_key) { "no_presence_of_attribute" }
              let(:criticity) { "warning" }

              it "should create warning message" do
                subject

                expect(control_run.control_messages).to include(expected_message)
              end
            end
          end
        end

        describe "#country" do
          let(:attribute_name) { "country" }
          let(:target_attribute) { "country" }

          context "when value is not present" do
            before { company.update country_code: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#time_zone" do
          let(:attribute_name) { "time_zone" }
          let(:target_attribute) { "time_zone" }

          context "when value is not present" do
            before { company.update time_zone: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#default_language" do
          let(:attribute_name) { "default_language" }
          let(:target_attribute) { "default_language" }

          context "when value is not present" do
            before { company.update default_language: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#default_contact_url" do
          let(:attribute_name) { "default_contact_url" }
          let(:target_attribute) { "default_contact_url" }

          context "when value is not present" do
            before { company.update default_contact_url: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#default_contact_phone" do
          let(:attribute_name) { "default_contact_phone" }
          let(:target_attribute) { "default_contact_phone" }

          context "when value is not present" do
            before { company.update default_contact_phone: nil }

            let(:message_key) { "no_presence_of_attribute" }
            let(:criticity) { "warning" }

            it "should create warning message" do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        describe "#default_contact_email" do
          let(:attribute_name) { "default_contact_email" }
          let(:target_attribute) { "default_contact_email" }

          context "when value is not present" do
            before { company.update default_contact_email: nil }

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