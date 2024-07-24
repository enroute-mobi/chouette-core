# frozen_string_literal: true

RSpec.describe Export::CodeProvider do
  subject(:code_provider) { Export::CodeProvider.new(export_scope) }
  let(:export_scope) { double }

  describe '#code' do
    subject { code_provider.code(value) }

    context 'when given value is nil' do
      let(:value) { nil }

      it { is_expected.to be_nil }
    end

    context 'when the given StopArea 1 has been indexed with "dummy"' do
      let(:value) { Chouette::StopArea.new(id: 1) }
      before { allow(code_provider).to receive(:stop_areas).and_return(double(code: 'dummy')) }

      it { is_expected.to eq('dummy') }
    end
  end

  describe Export::CodeProvider::Indexer::StopPoints do
    describe '#index' do
      subject { described_class.new(context.referential.stop_points, code_provider: code_provider).index }

      let(:code_provider) { Export::CodeProvider.new(double(routes: context.referential.routes), code_space: code_space) }

      let(:context) do
        Chouette.create do
          code_space short_name: 'test'

          route :first, codes: { test: 'first' }
          route :second, codes: { test: 'ACME:Route:A:LOC' }
        end
      end

      before do
        context.referential.switch
      end

      let(:code_space) { context.code_space }
      let(:first_route) { context.route(:first) }
      let(:second_route) { context.route(:second) }

      it do
        expected_codes = {
          first_route.stop_points.first.id => eq('StopPoint:first-0'),
          second_route.stop_points.last.id => Netex::ObjectId.parse('ACME:StopPoint:A-2:LOC'),
        }

        is_expected.to include(expected_codes)
      end
    end
  end

  describe Export::CodeProvider::Indexer::Default do
    context 'when model class is Chouette::StopArea' do
      subject(:model_code_provider) { described_class.new Chouette::StopArea.none }

      describe '#default_attribute' do
        subject { model_code_provider.default_attribute }

        it { is_expected.to eq('objectid') }
      end

      describe '#index' do
        describe 'with a dedicated CodeSpace' do
          subject { described_class.new(context.stop_area_referential.stop_areas, code_space: code_space).index }

          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              code_space :other, short_name: 'other'

              stop_area :first, codes: { test: 'first' }
              stop_area :second, codes: { test: 'second', other: 'second' }
              stop_area :third, objectid: 'third_objectid::LOC', codes: { other: 'value' }
              stop_area :fourth, objectid: 'fourth_objectid::LOC', codes: { test: %w[fourth1 fourth2] }
              stop_area :last, objectid: 'last_objectid::LOC', codes: { test: 'first' }
            end
          end

          let(:code_space) { context.code_space }
          let(:first) { context.stop_area(:first) }
          let(:second) { context.stop_area(:second) }
          let(:third) { context.stop_area(:third) }
          let(:fourth) { context.stop_area(:fourth) }
          let(:last) { context.stop_area(:last) }

          it do
            expected_codes = {
              first.id => 'first',
              second.id => 'second',
              third.id => 'third_objectid::LOC',
              fourth.id => 'fourth_objectid::LOC',
              last.id => 'last_objectid::LOC'
            }

            is_expected.to eq expected_codes
          end
        end

        describe 'with registration number' do
          subject { described_class.new(context.stop_area_referential.stop_areas, code_space: context.workgroup.code_spaces.default).index }

          let(:context) do
            Chouette.create do
              stop_area :first, registration_number: 'first'
              stop_area :second, registration_number: 'second'
              stop_area :third, objectid: 'third_objectid::LOC', registration_number: nil
              # stop_area :last, objectid: 'last_objectid::LOC', registration_number: 'first'
            end
          end

          let(:code_space) { context.code_space }
          let(:first) { context.stop_area(:first) }
          let(:second) { context.stop_area(:second) }
          let(:third) { context.stop_area(:third) }
          # let(:last) { context.stop_area(:last) }

          it do
            expected_codes = {
              first.id => 'first',
              second.id => 'second',
              third.id => 'third_objectid::LOC',
              # last.id => 'last_objectid::LOC'
            }

            is_expected.to eq expected_codes
          end
        end
      end
    end

    context 'when model class is Chouette::Route' do
      subject(:model_code_provider) { described_class.new Chouette::Route.none }

      describe '#default_attribute' do
        subject { model_code_provider.default_attribute }

        it { is_expected.to eq('objectid') }
      end

      describe '#index' do
        describe 'with a dedicated CodeSpace' do
          subject { described_class.new(context.referential.routes, code_space: code_space).index }

          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              code_space :other, short_name: 'other'

              route :first, codes: { test: 'first' }
              route :second, codes: { test: 'second', other: 'second' }
              route :third, objectid: 'third_objectid::LOC', codes: { other: 'value' }
              route :fourth, objectid: 'fourth_objectid::LOC', codes: { test: %w[fourth1 fourth2] }
              route :last, objectid: 'last_objectid::LOC', codes: { test: 'first' }
            end
          end

          let(:code_space) { context.code_space }
          let(:first) { context.route(:first) }
          let(:second) { context.route(:second) }
          let(:third) { context.route(:third) }
          let(:fourth) { context.route(:fourth) }
          let(:last) { context.route(:last) }

          before do
            context.referential.switch
          end

          it do
            expected_codes = {
              first.id => 'first',
              second.id => 'second',
              third.id => 'third_objectid::LOC',
              fourth.id => 'fourth_objectid::LOC',
              last.id => 'last_objectid::LOC'
            }

            is_expected.to eq expected_codes
          end
        end
      end
    end

    context 'when model class is Chouette::TimeTable' do
      subject(:model_code_provider) { described_class.new Chouette::TimeTable.none }

      describe '#default_attribute' do
        subject { model_code_provider.default_attribute }

        it { is_expected.to eq('objectid') }
      end

      describe '#index' do
        describe 'with a dedicated CodeSpace' do
          subject { described_class.new(context.referential.time_tables, code_space: code_space).index }

          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              code_space :other, short_name: 'other'

              time_table :first, codes: { test: 'first' }
              time_table :second, codes: { test: 'second', other: 'second' }
              time_table :third, objectid: 'third_objectid::LOC', codes: { other: 'value' }
              time_table :fourth, objectid: 'fourth_objectid::LOC', codes: { test: %w[fourth1 fourth2] }
              time_table :last, objectid: 'last_objectid::LOC', codes: { test: 'first' }
            end
          end

          let(:code_space) { context.code_space }
          let(:first) { context.time_table(:first) }
          let(:second) { context.time_table(:second) }
          let(:third) { context.time_table(:third) }
          let(:fourth) { context.time_table(:fourth) }
          let(:last) { context.time_table(:last) }

          before do
            context.referential.switch
          end

          it do
            expected_codes = {
              first.id => 'first',
              second.id => 'second',
              third.id => 'third_objectid::LOC',
              fourth.id => 'fourth_objectid::LOC',
              last.id => 'last_objectid::LOC'
            }

            is_expected.to eq expected_codes
          end
        end
      end
    end

    context 'when model class is PointOfInterest' do
      subject(:model_code_provider) { described_class.new PointOfInterest::Base.none }

      describe '#default_attribute' do
        subject { model_code_provider.default_attribute }

        it { is_expected.to eq('uuid') }
      end

      describe '#index' do
        subject { described_class.new(context.shape_referential.point_of_interests, code_space: code_space).index }

        let(:context) do
          Chouette.create do
            code_space short_name: 'test'
            code_space :other, short_name: 'other'

            point_of_interest :first, codes: { test: 'first' }
            point_of_interest :second, codes: { test: 'second', other: 'second' }
            point_of_interest :third, uuid: '91a8cf58-21f5-405b-868b-15ef92954c47', codes: { other: 'value' }
            point_of_interest :last, uuid: 'a82a120d-128c-4085-8595-fc81118c3cca', codes: { test: 'first' }
          end
        end

        let(:code_space) { context.code_space }
        let(:first) { context.point_of_interest(:first) }
        let(:second) { context.point_of_interest(:second) }
        let(:third) { context.point_of_interest(:third) }
        let(:last) { context.point_of_interest(:last) }

        it do
          expected_codes = {
            first.id => 'first',
            second.id => 'second',
            third.id => '91a8cf58-21f5-405b-868b-15ef92954c47',
            last.id => 'a82a120d-128c-4085-8595-fc81118c3cca'
          }

          is_expected.to eq(expected_codes)
        end
      end
    end
  end

  describe Export::CodeProvider::Indexer::TimeTables do
    subject(:model_code_provider) { described_class.new Chouette::TimeTable.none }

    describe '#default_attribute' do
      subject { model_code_provider.default_attribute }

      it { is_expected.to eq('objectid') }
    end

    describe '#index' do
      describe 'with a dedicated CodeSpace' do
        subject do
          described_class.new(
            context.referential.time_tables,
            code_space: code_space
          ).index
        end

        let(:context) do
          Chouette.create do
            code_space :test, short_name: 'test'
            code_space :other, short_name: 'other'

            time_table :first, codes: { test: 'first' }
            time_table :second, codes: { test: 'second', other: 'second' }
            time_table :third, objectid: 'third_objectid::LOC', codes: { other: 'value' }
            time_table :fourth, objectid: 'fourth_objectid::LOC', codes: { test: %w[fourth1 fourth2] }
            time_table :last, objectid: 'last_objectid::LOC', codes: { test: 'first' }
          end
        end

        let(:code_space) { context.code_space(:test) }
        let(:first) { context.time_table(:first) }
        let(:second) { context.time_table(:second) }
        let(:third) { context.time_table(:third) }
        let(:fourth) { context.time_table(:fourth) }
        let(:last) { context.time_table(:last) }

        before do
          context.referential.switch
        end

        it do
          expected_codes = {
            first.id => 'first',
            second.id => 'second',
            third.id => 'third_objectid::LOC',
            fourth.id => 'fourth2',
            last.id => 'last_objectid::LOC'
          }

          is_expected.to eq expected_codes
        end
      end
    end
  end

  describe Export::CodeProvider::Null do
    subject(:code_provider) { Export::CodeProvider.null }

    describe '#code' do
      subject { code_provider.code(value) }

      context 'when given value is nil' do
        let(:value) { nil }

        it { is_expected.to be_nil }
      end

      context 'when a StopArea 1 is given' do
        let(:value) { Chouette::StopArea.new(id: 1) }

        it { is_expected.to be_nil }
      end
    end

    describe '#stop_areas' do
      subject(:stop_areas) { code_provider.stop_areas }

      describe '#code' do
        subject { stop_areas.code(value) }

        context 'when given value is nil' do
          let(:value) { nil }

          it { is_expected.to be_nil }
        end

        context 'when 1 is given' do
          let(:value) { 1 }

          it { is_expected.to be_nil }
        end
      end
    end
  end
end
