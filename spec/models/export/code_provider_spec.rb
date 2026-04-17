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
      before { allow(code_provider).to receive(:collection).with('stop_areas').and_return(double(code: 'dummy')) }

      it { is_expected.to eq('dummy') }
    end
  end

  describe Export::CodeProvider::Indexer do
    describe '.create' do
      subject { described_class.create(collection, code_provider: code_provider, code_space: code_space, klass: klass) }

      let(:code_space) { Chouette.create { code_space }.code_space }
      let(:klass) { nil }

      context 'with a stop area collection' do
        let(:collection) { Chouette::StopArea.none }

        context 'with code space' do
          it { is_expected.to be_a(Export::CodeProvider::Indexer::Default) }
        end

        context 'without code space' do
          let(:code_space) { nil }

          it { is_expected.to be_a(Export::CodeProvider::Indexer::Default) }
        end
      end

      context 'with a stop point collection' do
        let(:collection) { Chouette::StopPoint.none }

        context 'with code space' do
          it { is_expected.to be_a(Export::CodeProvider::Indexer::StopPoints) }
        end

        context 'without code space' do
          let(:code_space) { nil }

          it { is_expected.to be_a(Export::CodeProvider::Indexer::Default) }
        end
      end

      context 'with a route collection' do
        let(:collection) { Chouette::Route.none }

        context 'with code space' do
          it { is_expected.to be_a(Export::CodeProvider::Indexer::Older) }
        end

        context 'without code space' do
          let(:code_space) { nil }

          it { is_expected.to be_a(Export::CodeProvider::Indexer::Default) }
        end
      end

      context 'with a journey pattern collection' do
        let(:collection) { Chouette::JourneyPattern.none }

        context 'with code space' do
          it { is_expected.to be_a(Export::CodeProvider::Indexer::Older) }
        end

        context 'without code space' do
          let(:code_space) { nil }

          it { is_expected.to be_a(Export::CodeProvider::Indexer::Default) }
        end
      end

      context 'with a vehicle journey collection' do
        let(:collection) { Chouette::VehicleJourney.none }

        context 'with code space' do
          it { is_expected.to be_a(Export::CodeProvider::Indexer::Older) }
        end

        context 'without code space' do
          let(:code_space) { nil }

          it { is_expected.to be_a(Export::CodeProvider::Indexer::Default) }
        end
      end

      context 'with a time table collection' do
        let(:collection) { Chouette::TimeTable.none }

        context 'with klass' do
          let(:klass) { Export::CodeProvider::Indexer::CodeUuid }

          context 'with code space' do
            it { is_expected.to be_a(Export::CodeProvider::Indexer::CodeUuid) }
          end

          context 'without code space' do
            let(:code_space) { nil }

            it { is_expected.to be_a(Export::CodeProvider::Indexer::Default) }
          end
        end

        context 'without klass' do
          context 'with code space' do
            it { is_expected.to be_a(Export::CodeProvider::Indexer::Older) }
          end

          context 'without code space' do
            let(:code_space) { nil }

            it { is_expected.to be_a(Export::CodeProvider::Indexer::Default) }
          end
        end
      end
    end
  end

  describe Export::CodeProvider::Indexer::StopPoints do
    describe '#index' do
      subject { described_class.new(context.referential.stop_points, code_provider: code_provider).index }

      let(:code_provider) do
        Export::CodeProvider.new(double(routes: context.referential.routes), code_space: code_space)
      end

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
          second_route.stop_points.last.id => Netex::ObjectId.parse('ACME:StopPoint:A-2:LOC')
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
          subject do
            described_class.new(context.stop_area_referential.stop_areas,
                                code_space: context.workgroup.code_spaces.default).index
          end

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
              third.id => 'third_objectid::LOC'
              # last.id => 'last_objectid::LOC'
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

  describe Export::CodeProvider::Indexer::CodeUuid do
    context 'when model class is Chouette::StopArea' do
      subject(:model_code_provider) { described_class.new Chouette::StopArea.none }

      describe '#index' do
        subject { described_class.new(context.stop_area_referential.stop_areas, code_space: code_space).index }

        let(:context) do
          Chouette.create do
            code_space short_name: 'test'
            code_space :other, short_name: 'other'

            stop_area :first, codes: { test: 'first' }
            stop_area :second, codes: { test: 'second', other: 'second' }
            stop_area :third, objectid: 'chouette:StopArea:third:LOC', codes: { other: 'value' }
            stop_area :fourth, objectid: 'chouette:StopArea:fourth:LOC', codes: { test: %w[fourth1 fourth2] }
            stop_area :last, objectid: 'chouette:StopArea:last:LOC', codes: { test: 'first' }
            stop_area :non_match, objectid: 'NOPE'
          end
        end

        let(:code_space) { context.code_space }
        let(:first) { context.stop_area(:first) }
        let(:second) { context.stop_area(:second) }
        let(:third) { context.stop_area(:third) }
        let(:fourth) { context.stop_area(:fourth) }
        let(:last) { context.stop_area(:last) }
        let(:non_match) { context.stop_area(:non_match) }

        it do
          expected_codes = {
            first.id => 'first',
            second.id => 'second',
            third.id => 'third',
            fourth.id => 'fourth',
            last.id => 'first-last',
            non_match.id => 'NOPE'
          }

          is_expected.to eq expected_codes
        end
      end
    end
  end

  describe Export::CodeProvider::Indexer::Older do
    context 'when model class is Chouette::Route' do
      subject(:model_code_provider) { described_class.new Chouette::Route.none }

      describe '#default_attribute' do
        subject { model_code_provider.default_attribute }

        it { is_expected.to eq('objectid') }
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
              fourth.id => 'fourth1',
              last.id => 'last_objectid::LOC'
            }

            is_expected.to eq expected_codes
          end
        end
      end
    end
  end

  describe Export::CodeProvider::Indexer::Footnotes do
    subject(:indexer) do
      described_class.new(referential.footnotes, code_space: code_space, code_provider: code_provider)
    end

    let(:referential) { context.referential }
    let(:code_space) { context.code_space(:code_space) }
    let(:code_provider) { Export::CodeProvider.new(double(footnotes: referential.footnotes, lines: referential.lines)) }

    describe '#index' do
      subject { indexer.index }

      let(:footnote) { context.footnote(:footnote) }
      let(:line_technical) { Netex::ObjectId.parse(footnote.line.objectid).technical }

      before { referential.switch }

      context 'when foonote has no code' do
        context 'when footnote has no line' do
          context 'without data_source_ref' do
            let(:context) do
              Chouette.create do
                code_space :code_space
                footnote :footnote, line: nil
              end
            end

            it do
              is_expected.to eq(
                { footnote.id => Netex::ObjectId.parse("chouette:Notice:#{footnote.id}:LOC") }
              )
            end
          end

          context 'with data_source_ref' do
            let(:context) do
              Chouette.create do
                code_space :code_space
                footnote :footnote, line: nil, data_source_ref: 'some_data_souce_ref'
              end
            end

            it do
              is_expected.to eq(
                { footnote.id => Netex::ObjectId.parse("some_data_souce_ref:Notice:#{footnote.id}:LOC") }
              )
            end
          end
        end

        context 'when footnote has line' do
          context 'without data_source_ref' do
            let(:context) do
              Chouette.create do
                code_space :code_space
                footnote :footnote
              end
            end

            it do
              is_expected.to eq(
                { footnote.id => Netex::ObjectId.parse("chouette:Notice:#{line_technical}-#{footnote.id}:LOC") }
              )
            end
          end

          context 'with data_source_ref' do
            let(:context) do
              Chouette.create do
                code_space :code_space
                footnote :footnote, data_source_ref: 'some_data_souce_ref'
              end
            end

            it do
              is_expected.to eq(
                { footnote.id => Netex::ObjectId.parse("some_data_souce_ref:Notice:#{line_technical}-#{footnote.id}:LOC") }
              )
            end
          end
        end
      end

      context 'when footnote has code' do
        context 'with the same code space' do
          context 'with count = 1' do
            let(:context) do
              Chouette.create do
                code_space :code_space, short_name: 'code_space'
                footnote :footnote, codes: { 'code_space' => 'some_code' }
              end
            end

            it do
              is_expected.to eq(
                { footnote.id => 'some_code' }
              )
            end
          end

          context 'with count = 2' do
            let(:context) do
              Chouette.create do
                code_space :code_space, short_name: 'code_space'
                footnote :footnote, codes: { 'code_space' => %w[some_code1 some_code2] }
              end
            end

            it do
              is_expected.to eq(
                { footnote.id => Netex::ObjectId.parse("chouette:Notice:#{line_technical}-#{footnote.id}:LOC") }
              )
            end
          end
        end

        context 'with another code space' do
          let(:context) do
            Chouette.create do
              code_space :code_space, short_name: 'code_space'
              code_space :other_code_space, short_name: 'other_code_space'
              footnote :footnote, codes: { 'other_code_space' => 'some_code' }
            end
          end

          it do
            is_expected.to eq(
              { footnote.id => Netex::ObjectId.parse("chouette:Notice:#{line_technical}-#{footnote.id}:LOC") }
            )
          end
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
