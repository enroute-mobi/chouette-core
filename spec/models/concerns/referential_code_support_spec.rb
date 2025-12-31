# frozen_string_literal: true

RSpec.describe ReferentialCodeSupport do
  let(:context) do
    Chouette.create do
      code_space :test, short_name: 'test'
      code_space :other, short_name: 'other'

      referential do
        time_table :test_value, codes: { 'test' => 'value' }
        time_table :test_other, codes: { 'test' => 'other' }
        time_table :other_value, codes: { 'other' => 'value' }
        time_table :without
      end
    end
  end

  %i[test_value test_other other_value without].each do |time_table_id|
    let(time_table_id) { context.time_table(time_table_id) }
  end

  before { context.referential.switch }

  describe '.by_code' do
    subject { Chouette::TimeTable.by_code(code_space, 'value') }

    before { [test_value, test_other, other_value, without] }

    context 'with a code space' do
      let(:code_space) { context.code_space(:test) }

      it { is_expected.to contain_exactly(test_value) }
    end

    context 'with a code space id' do
      let(:code_space) { context.code_space(:test).id }

      it { is_expected.to contain_exactly(test_value) }
    end

    context 'with nil' do
      let(:code_space) { nil }

      it { is_expected.to be_empty }
    end
  end

  describe '.with_code' do
    subject { Chouette::TimeTable.with_code(code_space) }

    before { [test_value, test_other, other_value, without] }

    context 'with a code space' do
      let(:code_space) { context.code_space(:test) }

      it { is_expected.to contain_exactly(test_value, test_other) }
    end

    context 'with a code space id' do
      let(:code_space) { context.code_space(:test).id }

      it { is_expected.to contain_exactly(test_value, test_other) }
    end

    context 'with nil' do
      let(:code_space) { nil }

      it { is_expected.to be_empty }
    end
  end

  describe '.without_code' do
    subject { Chouette::TimeTable.without_code(code_space) }

    before { [test_value, test_other, other_value, without] }

    context 'with a code space' do
      let(:code_space) { context.code_space(:test) }

      it { is_expected.to contain_exactly(other_value, without) }
    end

    context 'with a code space id' do
      let(:code_space) { context.code_space(:test).id }

      it { is_expected.to contain_exactly(other_value, without) }
    end

    context 'with nil' do
      let(:code_space) { nil }

      it { is_expected.to match_array(Chouette::TimeTable.all) }
    end
  end
end
