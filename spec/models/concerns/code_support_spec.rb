# frozen_string_literal: true

RSpec.describe CodeSupport do
  with_model :model do
    model do
      include ::CodeSupport
    end
  end

  let(:context) do
    Chouette.create do
      code_space :test, short_name: 'test'
      code_space :other, short_name: 'other'
    end
  end

  let(:test_value) do
    Model.create!(codes_attributes: { '0' => { code_space_id: context.code_space(:test).id, value: 'value' } })
  end
  let(:test_other) do
    Model.create!(codes_attributes: { '0' => { code_space_id: context.code_space(:test).id, value: 'other' } })
  end
  let(:other_value) do
    Model.create!(codes_attributes: { '0' => { code_space_id: context.code_space(:other).id, value: 'value' } })
  end
  let(:without) { Model.create! }

  describe '.by_code' do
    subject { Model.by_code(code_space, 'value') }

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
    subject { Model.with_code(code_space) }

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
    subject { Model.without_code(code_space) }

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

      it { is_expected.to match_array(Model.all) }
    end
  end

  describe CodeSupport::Validator::CodeSpaceUniqueness do
    subject(:validator) { described_class.new(codes) }
    let(:codes) { [] }

    describe '#duplicated_codes' do
      subject { validator.duplicated_codes }

      context 'when codes is empty' do
        let(:codes) { [] }

        it { is_expected.to be_empty }
      end

      context "when uniq Code Space doesn't allow multiple values" do
        let(:uniq) { CodeSpace.new(id: 42, allow_multiple_values: false) }

        context 'when codes is uniq:1' do
          let(:codes) do
            [
              Code.new(value: '1', code_space: uniq)
            ]
          end

          it { is_expected.to be_empty }
        end

        context 'when codes is uniq:1 and other:1' do
          let(:codes) do
            [
              Code.new(value: '1', code_space: uniq),
              Code.new(value: '1', code_space: CodeSpace.new(id: 1))
            ]
          end

          it { is_expected.to be_empty }
        end

        context 'when codes are uniq:1 and uniq:2' do
          let(:codes) do
            [
              Code.new(value: '1', code_space: uniq),
              Code.new(value: '2', code_space: uniq)
            ]
          end

          it { is_expected.to match_array(codes) }
        end

        context 'when codes are uniq:1, uniq:2 and other:1' do
          let(:codes) do
            [
              Code.new(value: '1', code_space: uniq),
              Code.new(value: '2', code_space: uniq),
              Code.new(value: '1', code_space: CodeSpace.new(id: 1))
            ]
          end

          it {
            is_expected.to include(an_object_having_attributes(value: '1', code_space: uniq),
                                   an_object_having_attributes(value: '2', code_space: uniq))
          }
        end
      end

      context 'when other Code Space allows multiple values' do
        let(:other) { CodeSpace.new(id: 42, allow_multiple_values: true) }

        context 'when codes is other:1' do
          let(:codes) do
            [
              Code.new(value: '1', code_space: other)
            ]
          end

          it { is_expected.to be_empty }
        end

        context 'when codes are other:1 and other:2' do
          let(:codes) do
            [
              Code.new(value: '1', code_space: other),
              Code.new(value: '2', code_space: other)
            ]
          end

          it { is_expected.to be_empty }
        end
      end
    end

    describe 'validate' do
      subject { validator.validate }

      context 'when duplicated_codes is empty' do
        before { allow(validator).to receive(:duplicated_codes).and_return([]) }

        it { is_expected.to be_truthy }
      end

      context 'when duplicated_codes contains a Code' do
        let(:code) { Code.new(value: '1', code_space: CodeSpace.new(short_name: 'test')) }

        before { allow(validator).to receive(:duplicated_codes).and_return([code]) }

        it { is_expected.to be_falsy }

        describe 'code errors' do
          subject { code.errors.details }

          before { validator.validate }

          it { is_expected.to eq({ value: [{ error: :duplicate_code_spaces_in_codes, code_space: 'test' }] }) }
        end
      end
    end
  end

  describe CodeSupport::Validator::ValueUniqueness do
    subject(:validator) { described_class.new(codes) }
    let(:codes) { [] }

    describe '#duplicated_codes' do
      subject { validator.duplicated_codes }

      context 'when codes is empty' do
        let(:codes) { [] }

        it { is_expected.to be_empty }
      end

      let(:test) { CodeSpace.new(id: 42) }

      context 'when codes is test:1 and other:1' do
        let(:codes) do
          [
            Code.new(value: '1', code_space: test),
            Code.new(value: '1', code_space: CodeSpace.new(id: 2))
          ]
        end

        it { is_expected.to be_empty }
      end

      context 'when codes is test:1 and test:1' do
        let(:codes) do
          [
            Code.new(value: '1', code_space: test),
            Code.new(value: '1', code_space: test)
          ]
        end

        it { is_expected.to match_array(codes) }
      end
    end

    describe 'validate' do
      subject { validator.validate }

      context 'when duplicated_codes is empty' do
        before { allow(validator).to receive(:duplicated_codes).and_return([]) }

        it { is_expected.to be_truthy }
      end

      context 'when duplicated_codes contains a Code' do
        let(:code) { Code.new(value: '1', code_space: CodeSpace.new(short_name: 'test')) }

        before { allow(validator).to receive(:duplicated_codes).and_return([code]) }

        it { is_expected.to be_falsy }

        describe 'code errors' do
          subject { code.errors.details }

          before { validator.validate }

          it { is_expected.to eq({ value: [{ error: :duplicate_values_in_codes }] }) }
        end
      end
    end
  end
end
