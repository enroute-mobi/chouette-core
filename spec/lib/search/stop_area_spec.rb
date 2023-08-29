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

  let(:scope) { Chouette::StopArea.where(name: ['1', '2', '3']) }

  context 'search with pagination' do
    subject { Search::StopArea.new(scope, search: { per_page: 2, page: 1 }).collection }

    it 'returns first 2 stop areas from the given scope' do
      is_expected.to match_array([first, second])
    end
  end

  context 'search without pagination' do
    subject { Search::StopArea.new(scope, search: { per_page: 2, page: 1 }).without_pagination.collection }

    it 'returns all stop areas from the given scope' do
      is_expected.to match_array([first, second, last])
    end
  end

  context 'search with order and pagination' do
    subject { Search::StopArea.new(scope, search: { per_page: 2, page: 1, order: { name: :desc } }).collection }

    it 'returns 2 stop areas with order for the name attribute from the given scope' do
      is_expected.to eq [last, second]
    end
  end

  context 'search with order' do
    subject { Search::StopArea.new(scope, search: { order: { name: :desc } }).collection }

    it 'returns all stop areas without order for the name attribute from the given scope' do
      is_expected.to eq [last, second, first]
    end
  end

  context 'search without order and without pagination' do
    subject do
      Search::StopArea.new(
        scope,
        search: { per_page: 2, page: 1, order: { name: :desc } }
      ).without_order.without_pagination.collection
    end

    it 'returns all stop areas without order for the name attribute from the given scope' do
      is_expected.to eq [first, second, last]
    end
  end
end
