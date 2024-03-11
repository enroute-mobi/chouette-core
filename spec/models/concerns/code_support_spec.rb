# frozen_string_literal: true

RSpec.describe CodeSupport do
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
