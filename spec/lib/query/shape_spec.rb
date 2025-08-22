# frozen_string_literal: true

RSpec.describe Query::Shape do
  subject { query.scope }

  let(:context) do
    Chouette.create do
      workbench do
        shape :expected
        shape
      end
    end
  end
  let(:query) { described_class.new(context.workbench.shapes) }
  let(:shape) { context.shape(:expected) }

  describe '#text' do
    before { query.text(text) }

    context 'when given text is blank' do
      let(:text) { '' }

      it 'ignores this criteria' do
        is_expected.to match_array(context.workbench.shapes)
      end
    end

    context "when given text is 'Dummy'" do
      let(:text) { 'Dummy' }

      context "when a Shape is named 'Dummy'" do
        before { shape.update(name: 'Dummy') }

        it { is_expected.to contain_exactly(shape) }
      end

      context "when a Shape is named 'DUMMY'" do
        before { shape.update(name: 'DUMMY') }

        it { is_expected.to contain_exactly(shape) }
      end

      context "when a Shape is named 'Shape Dummy Sample'" do
        before { shape.update(name: 'Shape Dummy Sample') }

        it { is_expected.to contain_exactly(shape) }
      end
    end

    context 'when given text in a part of the uuid' do
      let(:text) { '1234' }

      before { shape.update(uuid: '7548ff54-0c9f-1234-9f6d-0894a1be985d') }

      it { is_expected.to contain_exactly(shape) }
    end
  end
end
