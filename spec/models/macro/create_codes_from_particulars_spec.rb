# frozen_string_literal: true

RSpec.describe Macro::CreateCodesFromParticulars do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end
end

RSpec.describe Macro::CreateCodesFromParticulars::Run do
  it { should validate_presence_of :target_model }
  it do
    should enumerize(:target_model).in(
      %w[Line StopArea Company]
    )
  end

  let(:macro_list_run) do
    Macro::List::Run.create workbench: context.workbench
  end

  let(:macro_run) do
    described_class.create(
      macro_list_run: macro_list_run,
      position: 0,
      options: {
        target_model: target_model,
        particular_code_space_id: particular_code_space.id,
        referent_code_space_id: referent_code_space.id
      }
    )
  end

  describe '#run' do
    subject { macro_run.run }

    let(:expected_codes) do 
      [
        an_object_having_attributes(
          code_space: referent_code_space,
          value: 'first',
          resource: referent
        ),
        an_object_having_attributes(
          code_space: referent_code_space,
          value: 'second',
          resource: referent
        )
      ]
    end

    let(:expected_messages) do 
      [
        an_object_having_attributes(
          criticity: 'info',
          message_attributes: {
            'referent_name' => 'Referent',
            'code_value' => 'first'
          },
          source: referent
        ),

        an_object_having_attributes(
          criticity: 'info',
          message_attributes: {
            'referent_name' => 'Referent',
            'code_value' => 'second'
          },
          source: referent
        )
      ]
    end

    describe 'StopArea' do
      let(:target_model) { 'StopArea' }
      let(:referent) { context.stop_area(:referent) }
      let(:first_particular) { context.stop_area(:referent) }
      let(:second_particular) { context.stop_area(:referent) }
      let(:particular_code_space) { context.code_space(:particular_code_space) }
      let(:referent_code_space) { context.code_space(:referent_code_space) }

      let(:context) do
        Chouette.create do
          code_space :particular_code_space, short_name: 'source'
          code_space :referent_code_space, short_name: 'target'
          code_space :other_code_space, short_name: 'other'

          stop_area :referent, name: 'Referent', is_referent: true, codes: { 'target' => 'existing' }

          stop_area :first_particular, referent: :referent, codes: { 'source' => 'first', 'other' => 'Other' }
          stop_area :second_particular, referent: :referent, codes: { 'source' => ['second', 'existing'] } 
        end
      end

      it 'should create codes' do
        expect { subject }.to change { referent.codes.count }.from(1).to(3)

        expected_codes.each do |code|
          expect(referent.reload.codes).to include(code)
        end
      end

      it 'should create macro messages' do
        expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(2)

        expected_messages.each do |expected_message|
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end
    end

    describe 'Line' do
      let(:target_model) { 'Line' }
      let(:referent) { context.line(:referent) }
      let(:first_particular) { context.line(:referent) }
      let(:second_particular) { context.line(:referent) }
      let(:particular_code_space) { context.code_space(:particular_code_space) }
      let(:referent_code_space) { context.code_space(:referent_code_space) }

      let(:context) do
        Chouette.create do
          code_space :particular_code_space, short_name: 'source'
          code_space :referent_code_space, short_name: 'target'
          code_space :other_code_space, short_name: 'other'

          line :referent, name: 'Referent', is_referent: true, codes: { 'target' => 'existing' }

          line :first_particular, referent: :referent, codes: { 'source' => 'first', 'other' => 'Other' }
          line :second_particular, referent: :referent, codes: { 'source' => ['second', 'existing'] }

          referential 
        end
      end

      it 'should create codes' do
        expect { subject }.to change { referent.codes.count }.from(1).to(3)

        expected_codes.each do |code|
          expect(referent.reload.codes).to include(code)
        end
      end

      it 'should create macro messages' do
        expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(2)

        expected_messages.each do |expected_message|
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end
    end

    describe 'Company' do
      let(:target_model) { 'Company' }
      let(:referent) { context.company(:referent) }
      let(:first_particular) { context.company(:referent) }
      let(:second_particular) { context.company(:referent) }
      let(:particular_code_space) { context.code_space(:particular_code_space) }
      let(:referent_code_space) { context.code_space(:referent_code_space) }

      let(:context) do
        Chouette.create do
          code_space :particular_code_space, short_name: 'source'
          code_space :referent_code_space, short_name: 'target'
          code_space :other_code_space, short_name: 'other'

          company :referent, name: 'Referent', is_referent: true, codes: { 'target' => 'existing' }

          company :first_particular, referent: :referent, codes: { 'source' => 'first', 'other' => 'Other' }
          company :second_particular, referent: :referent, codes: { 'source' => ['second', 'existing'] }
        end
      end

      it 'should create codes' do
        expect { subject }.to change { referent.codes.count }.from(1).to(3)

        expected_codes.each do |code|
          expect(referent.reload.codes).to include(code)
        end
      end

      it 'should create macro messages' do
        expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(2)

        expected_messages.each do |expected_message|
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end
    end
  end
end
