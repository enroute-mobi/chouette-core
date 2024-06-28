# frozen_string_literal: true

RSpec.describe Macro::CreateCodeFromUuid do
  it {
    is_expected.to validate_inclusion_of(:target_model)
      .in_array(%w[StopArea Line Company Route JourneyPattern TimeTable VehicleJourney])
  }

  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::CreateCodeFromUuid::Run do
    let(:macro_run) do
      described_class.create(
        macro_list_run: macro_list_run,
        position: 0,
        options: {
          target_model: target_model,
          code_space_id: code_space.id,
          format: format
        }
      )
    end

    let(:macro_list_run) do
      Macro::List::Run.create(referential: referential, workbench: workbench)
    end

    let(:context) do
      Chouette.create do
        code_space :public, short_name: 'public'
        code_space :test, short_name: 'test'

        company :company
        line :line, company: :company, registration_number: 'LINE42', codes: { 'public' => 'PUBLIC_LINE42' }
        stop_area :stop_area
        stop_area :other_stop_area

        referential lines: %i[line] do
          time_table
          route line: :line, stop_areas: %i[stop_area other_stop_area] do
            journey_pattern do
              vehicle_journey
            end
          end
        end
      end
    end

    let(:uuid_regexp) { '\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b' }

    let(:referential) { context.referential }
    let(:workbench) { context.workbench }
    let(:code_space) { context.code_space(:test) }

    let(:model_name) { model.name }
    let(:expected_message) do
      an_object_having_attributes(
        message_attributes: {
          'model_name' => model_name,
          'code_value' => match(code_value)
        }
      )
    end

    # rubocop:disable Style/FormatStringToken
    describe '#run' do
      subject { macro_run.run }

      before { referential.switch }

      context 'with StopArea' do
        let(:target_model) { 'StopArea' }
        let(:model) { context.stop_area(:stop_area) }

        context "when format is 'dummy:%{value}'" do
          let(:format) { 'dummy:%{value}' }
          let(:code_value) { /\Adummy:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context "when format is '%{line.code}:%{value}'" do
          let(:format) { '%{line.code}:%{value}' }
          let(:code_value) { /\A:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end
      end

      context 'with Line' do
        let(:target_model) { 'Line' }
        let(:model) { context.line(:line) }

        context "when format is 'dummy:%{value}'" do
          let(:format) { 'dummy:%{value}' }
          let(:code_value) { /\Adummy:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(1).to(2)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context "when format is '%{line.code}:%{value}'" do
          let(:format) { '%{line.code}:%{value}' }
          let(:code_value) { /\A:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(1).to(2)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end
      end

      context 'with Company' do
        let(:target_model) { 'Company' }
        let(:model) { context.company(:company) }

        context "when format is 'dummy:%{value}'" do
          let(:format) { 'dummy:%{value}' }
          let(:code_value) { /\Adummy:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context "when format is '%{line.code}:%{value}'" do
          let(:format) { '%{line.code}:%{value}' }
          let(:code_value) { /\A:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end
      end

      context 'with Route' do
        let(:target_model) { 'Route' }
        let(:model) { context.route }

        context "when format is 'dummy:%{value}'" do
          let(:format) { 'dummy:%{value}' }
          let(:code_value) { /\Adummy:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context "when format is '%{line.code}:%{value}'" do
          let(:format) { '%{line.code}:%{value}' }
          let(:code_value) { /\ALINE42:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context "when format is '%{line.code:public}:%{value}'" do
          let(:format) { '%{line.code:public}:%{value}' }
          let(:code_value) { /\APUBLIC_LINE42:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context "when format is '%{line.code:does_not_exist}:%{value}'" do
          let(:format) { '%{line.code:does_not_exist}:%{value}' }
          let(:code_value) { /\A:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end
      end

      context 'with JourneyPattern' do
        let(:target_model) { 'JourneyPattern' }
        let(:model) { context.journey_pattern }

        context "when format is 'dummy:%{value}'" do
          let(:format) { 'dummy:%{value}' }
          let(:code_value) { /\Adummy:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context "when format is '%{line.code}:%{value}'" do
          let(:format) { '%{line.code}:%{value}' }
          let(:code_value) { /\ALINE42:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context "when format is '%{line.code:public}:%{value}'" do
          let(:format) { '%{line.code:public}:%{value}' }
          let(:code_value) { /\APUBLIC_LINE42:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context "when format is '%{line.code:does_not_exist}:%{value}'" do
          let(:format) { '%{line.code:does_not_exist}:%{value}' }
          let(:code_value) { /\A:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end
      end

      context 'with TimeTable' do
        let(:target_model) { 'TimeTable' }
        let(:model) { context.time_table }
        let(:model_name) { model.comment }

        context "when format is 'dummy:%{value}'" do
          let(:format) { 'dummy:%{value}' }
          let(:code_value) { /\Adummy:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context "when format is '%{line.code}:%{value}'" do
          let(:format) { '%{line.code}:%{value}' }
          let(:code_value) { /\A:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end
      end

      context 'with VehicleJourney' do
        let(:target_model) { 'VehicleJourney' }
        let(:model) { context.vehicle_journey }
        let(:model_name) { model.published_journey_name }

        context "when format is 'dummy:%{value}'" do
          let(:format) { 'dummy:%{value}' }
          let(:code_value) { /\Adummy:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context "when format is '%{line.code}:%{value}'" do
          let(:format) { '%{line.code}:%{value}' }
          let(:code_value) { /\ALINE42:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end

          context 'with twice the same code in pattern' do
            let(:format) { '%{line.code}:%{line.code}:%{value}' }
            let(:code_value) { /\ALINE42:LINE42:#{uuid_regexp}\z/ }

            it 'should create code' do
              expect { subject }.to change { model.codes.count }.from(0).to(1)
              expect(macro_run.macro_messages).to include(expected_message)
            end
          end
        end

        context "when format is '%{line.code:public}:%{value}'" do
          let(:format) { '%{line.code:public}:%{value}' }
          let(:code_value) { /\APUBLIC_LINE42:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end

          context 'with twice the same code space in pattern' do
            let(:format) { '%{line.code:public}:%{line.code:public}:%{value}' }
            let(:code_value) { /\APUBLIC_LINE42:PUBLIC_LINE42:#{uuid_regexp}\z/ }

            it 'should create code' do
              expect { subject }.to change { model.codes.count }.from(0).to(1)
              expect(macro_run.macro_messages).to include(expected_message)
            end
          end
        end

        context "when format is '%{line.code:does_not_exist}:%{value}'" do
          let(:format) { '%{line.code:does_not_exist}:%{value}' }
          let(:code_value) { /\A:#{uuid_regexp}\z/ }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end
      end
    end
    # rubocop:enable Style/FormatStringToken
  end
end
