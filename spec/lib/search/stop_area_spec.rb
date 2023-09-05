RSpec.describe Search::StopArea do
  let!(:context) do
    Chouette.create do
      stop_area :first, name: '1'
      stop_area :second, name: '2'
      stop_area :last, name: '3'
    end
  end

  let(:first) { context.stop_area :first }
  let(:second) { context.stop_area :second }
  let(:last) { context.stop_area :last }

  let(:scope) { Chouette::StopArea.where(name: %w[1 2 3]) }

  subject { search.search(scope) }

  context 'search with pagination' do
    let(:search) { described_class.new(per_page: 2, page: 1) }

    it 'returns first 2 stop areas from the given scope' do
      is_expected.to match_array([first, second])
    end
  end

  context 'search without pagination' do
    let(:search) { described_class.new(per_page: 2, page: 1).without_pagination }

    it 'returns all stop areas from the given scope' do
      is_expected.to match_array([first, second, last])
    end
  end

  context 'search with order and pagination' do
    let(:search) { described_class.new(per_page: 2, page: 1, order: { name: :desc }) }

    it 'returns 2 stop areas with order for the name attribute from the given scope' do
      is_expected.to eq [last, second]
    end
  end

  context 'search with order' do
    let(:search) { described_class.new(order: { name: :desc }) }

    it 'returns all stop areas without order for the name attribute from the given scope' do
      is_expected.to eq [last, second, first]
    end
  end

  context 'search without order and without pagination' do
    let(:search) do
      described_class.new(per_page: 2, page: 1, order: { name: :desc }).without_order.without_pagination
    end

    it 'returns all stop areas without order for the name attribute from the given scope' do
      is_expected.to eq [first, second, last]
    end
  end
end
