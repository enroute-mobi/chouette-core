# frozen_string_literal: true

RSpec.describe Search::Base, type: :model do
  class self::Search < Search::Base # rubocop:disable Lint/ConstantDefinitionInBlock,Style/ClassAndModuleChildren
    attribute :name
    attr_accessor :context

    AUTHORIZED_GROUP_BY_ATTRIBUTES = (Search::Base::AUTHORIZED_GROUP_BY_ATTRIBUTES + %w[some_attribute]).freeze
    NUMERIC_ATTRIBUTES = { 'some_numeric_attribute' => 'EXTRACT(EPOCH FROM updated_at - created_at)' }.freeze

    class Order < ::Search::Order
      attribute :name, column: 'column'
      attr_accessor :context
    end

    class Chart < ::Search::Base::Chart
    end
  end

  let(:scope) { double }
  subject(:search) { self.class::Search.new }

  describe 'validations' do
    it { is_expected.to allow_value(nil).for(:chart_type) }
    it { is_expected.to allow_value('').for(:chart_type) }
    it { is_expected.to enumerize(:chart_type).in(%w[line pie column]) }

    it { is_expected.to allow_value(nil).for(:group_by_attribute) }
    it { is_expected.to allow_value('').for(:group_by_attribute) }

    it { is_expected.to allow_value(nil).for(:top_count) }
    it { is_expected.to allow_value('').for(:top_count) }

    it { is_expected.to allow_value(nil).for(:sort_by) }
    it { is_expected.to allow_value('').for(:sort_by) }
    it { is_expected.to enumerize(:sort_by).in(%w[value label]) }

    it { is_expected.to allow_value(nil).for(:aggregate_operation) }
    it { is_expected.to allow_value('').for(:aggregate_operation) }
    it { is_expected.to enumerize(:aggregate_operation).in(%w[count sum average]) }

    it { is_expected.to allow_value(nil).for(:aggregate_attribute) }
    it { is_expected.to allow_value('').for(:aggregate_attribute) }

    context 'when chart_type is present' do
      before { search.chart_type = 'line' }

      it { is_expected.to allow_value('some_attribute').for(:group_by_attribute) }
      it { is_expected.to allow_value('date').for(:group_by_attribute) }
      it { is_expected.to allow_value('hour_of_day').for(:group_by_attribute) }
      it { is_expected.to allow_value('day_of_week').for(:group_by_attribute) }
      it { is_expected.not_to allow_value(nil).for(:group_by_attribute) }
      it { is_expected.not_to allow_value('').for(:group_by_attribute) }
      it { is_expected.not_to allow_value('some_other_attribute').for(:group_by_attribute) }

      it { is_expected.to allow_value(10).for(:top_count) }
      it { is_expected.to allow_value('10').for(:top_count) }
      it { is_expected.not_to allow_value(nil).for(:top_count) }
      it { is_expected.not_to allow_value('').for(:top_count) }
      it { is_expected.not_to allow_value(-1).for(:top_count) }
      it { is_expected.not_to allow_value(0).for(:top_count) }

      it { is_expected.to allow_value('value').for(:sort_by) }
      it { is_expected.to allow_value('label').for(:sort_by) }
      it { is_expected.not_to allow_value(nil).for(:sort_by) }
      it { is_expected.not_to allow_value('').for(:sort_by) }

      it { is_expected.to allow_value(nil).for(:aggregate_attribute) }
      it { is_expected.to allow_value('').for(:aggregate_attribute) }

      context 'when aggregate_attribute is "sum"' do
        before { search.aggregate_operation = 'sum' }

        it { is_expected.to allow_value('some_numeric_attribute').for(:aggregate_attribute) }
        it { is_expected.not_to allow_value(nil).for(:aggregate_attribute) }
        it { is_expected.not_to allow_value('').for(:aggregate_attribute) }
        it { is_expected.not_to allow_value('some_other_attribute').for(:aggregate_attribute) }
      end

      context 'when aggregate_attribute is "average"' do
        before { search.aggregate_operation = 'average' }

        it { is_expected.to allow_value('some_numeric_attribute').for(:aggregate_attribute) }
        it { is_expected.not_to allow_value(nil).for(:aggregate_attribute) }
        it { is_expected.not_to allow_value('').for(:aggregate_attribute) }
        it { is_expected.not_to allow_value('some_other_attribute').for(:aggregate_attribute) }
      end
    end
  end

  describe '.from_params' do
    context "when params define a Search attribute (like search: { name: 'dummy' })" do
      subject { self.class::Search.from_params search: { name: 'dummy' } }

      it { is_expected.to have_attributes(name: 'dummy') }
    end

    context "when params define a Search Order attribute (like search: { order: { name: 'desc' }})" do
      subject(:search) { self.class::Search.from_params search: { order: { name: 'desc' } } }

      it { expect(search.order).to have_attributes(name: :desc) }
    end

    context "when context define a Search accessor (like { context: 'test' })" do
      subject { self.class::Search.from_params({}, context: 'test') }

      it { is_expected.to have_attributes(context: 'test') }
    end
  end

  describe '#search' do
    subject { search.search(scope) }

    context "when the Search isn't valid" do
      let(:scope) { double none: double('None relation from scope') }

      before do
        allow(search).to receive(:valid?).and_return(false)
      end

      it { is_expected.to be(scope.none) }
    end

    context 'when the Search is valid' do
      let(:query) { double scope: scope }

      before do
        allow(search).to receive(:valid?).and_return(true)
        allow(search).to receive(:query).and_return(query)

        allow(scope).to receive(:order).and_return(scope)
        allow(scope).to receive(:paginate).and_return(scope)
      end

      it 'is the Query scope' do
        is_expected.to eq(query.scope)
      end

      it 'is paginated with paginate attributes' do
        search.per_page = 42
        search.page = 7

        expect(scope).to receive(:paginate).with(per_page: 42, page: 7).and_return(scope)

        subject
      end

      it 'is ordered with order hash' do
        allow(search.order).to receive(:order_hash).and_return(name: :desc)
        expect(scope).to receive(:order).with(search.order.order_hash).and_return(scope)

        subject
      end
    end
  end

  describe '#graphical?' do
    subject { search.graphical? }

    it { is_expected.to eq(false) }

    context 'when a chart type is defined' do
      before { search.chart_type = 'line' }
      it { is_expected.to eq(true) }
    end
  end

  describe '#chart' do
    subject { search.chart(scope) }

    before { search.chart_type = 'line' }

    context "when the Search isn't valid" do
      let(:scope) { double none: double('None relation from scope') }

      before { allow(search).to receive(:valid?).and_return(false) }

      it { is_expected.to be_nil }
    end

    context 'when chart_type is nil' do
      before { search.chart_type = nil }

      it { is_expected.to be_nil }
    end

    context 'when the Search is valid' do
      before do
        allow(search).to receive(:valid?).and_return(true)
        allow(search).to receive(:search).and_return(scope)
      end

      it { is_expected.to be_an_instance_of(self.class::Search::Chart) }

      context 'with aggregate_attribute' do
        before do
          search.aggregate_operation = 'sum'
          search.aggregate_attribute = 'some_numeric_attribute'
        end

        it { is_expected.to have_attributes(aggregate_attribute: 'EXTRACT(EPOCH FROM updated_at - created_at)') }
      end
    end
  end

  describe '#attributes=' do
    context 'when a given key matches an defined attribute' do
      it 'changes the attribute value' do
        expect { search.attributes = { name: 'dummy' }; }.to change(search, :name).to('dummy')
      end
    end

    context 'when a given key matches a writer method but not a defined attribute' do
      it "doesn't change the Search" do
        expect { search.attributes = { context: 'dummy' } }.to_not change(search, :context)
      end
    end

    context 'when no given key/value matches an attribute' do
      subject { search.name = 'dummy' }
      it "doesn't change the attribute value" do
        expect { search.attributes = {}; }.to_not change(search, :name)
      end
    end
  end

  describe '#to_key' do
    subject { search.to_key }
    it { is_expected.to be_nil }
  end

  describe '.model_name' do
    subject { self.class::Search.model_name.to_s }

    # context "when the Search is a Controller subclass (like TestsController::Search)" do
    #   before { allow(self.class::Search).to receive(:name).and_return('TestsController::Search') }
    #   it { is_expected.to eq("Search::Tests") }
    # end

    context 'by default' do
      it { is_expected.to eq('Search') }
    end
  end

  describe 'per_page' do
    subject { search.per_page }

    context 'when no value is defined' do
      it { is_expected.to eq(30) }
    end

    context 'when per_page is defined with a non-numerical value' do
      before { search.per_page = 'abc' }
      it { is_expected.to eq(0) }
    end

    context 'when per_page is defined with less than 1 (like 0)' do
      before { search.per_page = 0 }

      it 'makes the Search invalid' do
        expect(search).to_not be_valid
      end
    end

    context 'when per_page is defined with more than 100 (like 101)' do
      before { search.per_page = 101 }

      it 'makes the Search invalid' do
        expect(search).to_not be_valid
      end
    end
  end

  describe 'page' do
    subject { search.page }

    context 'when page is defined with a non-numerical value' do
      before { search.page = 'abc' }
      it { is_expected.to eq(0) }
    end

    context 'when page is defined with less than 0 (like -1)' do
      before { search.page = -1 }

      it 'makes the Search invalid' do
        expect(search).to_not be_valid
      end
    end
  end

  describe '#paginate_attributes' do
    subject { search.paginate_attributes }

    context 'per_page is 30 and page is 2' do
      before do
        search.per_page = 30
        search.page = 2
      end

      it { is_expected.to eq(per_page: 30, page: 2) }
    end
  end

  describe '#order' do
    subject { search.order }
    it 'is an instance of the Search Order subclass' do
      is_expected.to be_an_instance_of(self.class::Search::Order)
    end
  end

  describe Search::Order do
    subject(:order) { self.class::Search::Order.new }

    describe 'initializer' do
      context "when Order is created with attributes, like name: 'asc'" do
        subject(:order) { self.class::Search::Order.new name: 'asc' }
        it { is_expected.to have_attributes(name: :asc) }
      end
    end

    describe '#attributes=' do
      context 'when a given key matches an defined attribute' do
        it 'changes the attribute value' do
          expect { search.attributes = { name: 'asc' }; }.to change(search, :name).to('asc')
        end
      end

      context 'when a given key matches a writer method but not a defined attribute' do
        it "doesn't change the Order" do
          expect { search.attributes = { context: 'dummy' } }.to_not change(search, :context)
        end
      end

      context "when a given key doesn't match any writer method" do
        it "doesn't change the Order (or raise error)" do
          expect { search.attributes = { dummy: 42 } }.to_not raise_error
        end
      end
    end

    describe 'attribute writer method' do
      Search::Order::Attribute::ASCENDANT_VALUES.each do |value|
        context "when the attribute value is #{value}" do
          it 'change the attribute value to :asc' do
            expect { order.name = value }.to change(order, :name).to(:asc)
          end
        end
      end

      Search::Order::Attribute::DESCENDANT_VALUES.each do |value|
        context "when the attribute value is #{value}" do
          it 'change the attribute value to :desc' do
            expect { order.name = value }.to change(order, :name).to(:desc)
          end
        end
      end
    end

    describe '.attributes' do
      subject { self.class::Search::Order.attributes }

      it 'contains all defined attributes' do
        is_expected.to contain_exactly(an_object_having_attributes(name: :name))
      end
    end

    describe '#order_hash' do
      subject { order.order_hash }

      context "when attribute name is :asc (and column 'column')" do
        before { order.name = :asc }
        it { is_expected.to eq('column' => :asc) }
      end
      context "when attribute name is :desc (and column 'column')" do
        before { order.name = :desc }
        it { is_expected.to eq('column' => :desc) }
      end
      context 'when attribute name is not defined' do
        before { order.name = nil }
        it { is_expected.to be_empty }
      end
    end

    describe '#joins' do
      let(:order_class) do
        Class.new(::Search::Order) do
          attribute :dummy, joins: :other
        end
      end
      let(:order) { order_class.new }
      subject { order.joins }

      it { is_expected.to be_an_instance_of(Array) }

      context 'when the attribute with joins option is included' do
        let(:order) { order_class.new(dummy: :asc) }
        it { is_expected.to contain_exactly(:other) }
      end

      context "when the attribute with joins option isn't included" do
        it { is_expected.to be_empty }
      end
    end

    describe '.attribute' do
      context 'when another Order is defined' do
        before do
          Class.new(::Search::Order) do
            attribute :other, default: :desc
          end
        end

        it 'defines attributes specific the Order class' do
          order_class = Class.new(::Search::Order) do
            attribute :dummy
          end
          expect(order_class.attributes).to contain_exactly(an_object_having_attributes(name: :dummy))
        end

        it 'defines defaults specific the Order class' do
          order_class = Class.new(::Search::Order) do
            attribute :dummy, default: :desc
          end
          expect(order_class.defaults).to eq(dummy: :desc)
        end
      end
    end
  end
end

RSpec.describe Search::Base::FromParamsBuilder do
  describe '.attributes' do
    subject { Search::Base::FromParamsBuilder.new(params).attributes }

    context 'when given params are nil' do
      let(:params) { nil }
      it { is_expected.to eq({}) }
    end

    context "when (legacy) 'sort' param is defined (like sort=name)" do
      let(:params) { { sort: 'name' } }
      it { is_expected.to eq(order: { name: :asc }) }
    end

    context "when (legacy) 'direction' param is defined (like sort=name & direction=desc)" do
      let(:params) { { sort: 'name', direction: 'desc' } }
      it { is_expected.to eq(order: { name: :desc }) }
    end

    context "when (legacy) 'sort' param is defined and search[order][<attribute>] is defined too" do
      let(:params) { { sort: 'name', search: { order: { other: :desc } } } }
      it { is_expected.to eq(order: { name: :asc }) }
    end

    context "when (legacy) 'per_page' param is defined (like per_page=10)" do
      let(:params) { { per_page: '10' } }
      it { is_expected.to eq({ per_page: '10' }) }
    end

    context "when (legacy) 'page' param is defined (like page=2)" do
      let(:params) { { page: '2' } }
      it { is_expected.to eq({ page: '2' }) }
    end

    context 'when search[text] param is defined' do
      let(:params) { { search: { text: 'dummy' } } }
      it { is_expected.to eq({ text: 'dummy' }) }
    end
  end
end

RSpec.describe Search::Base::Chart do
  class self::Chart < Search::Base::Chart # rubocop:disable Lint/ConstantDefinitionInBlock,Style/ClassAndModuleChildren
    private

    def all_more_keys_attribute_keys
      %w[key1 key2 key3]
    end

    def label_label_key_attribute_key(key)
      key.reverse
    end

    def joins_for_label_of_custom_label_attribute
      { relation: { other_relation: {} }, another_relation: {} }
    end

    def select_for_label_of_custom_label_attribute
      %w[other_relations.name another_relations.label]
    end
  end

  subject(:chart) do
    self.class::Chart.new(
      models,
      type: chart_type,
      group_by_attribute: group_by_attribute,
      first: first,
      top_count: top_count,
      sort_by: sort_by,
      aggregate_operation: aggregate_operation,
      aggregate_attribute: aggregate_attribute,
      display_percent: display_percent
    )
  end
  let(:models) { double }
  let(:chart_type) { 'line' }
  let(:group_by_attribute) { 'some_attribute' }
  let(:first) { false }
  let(:top_count) { 10 }
  let(:sort_by) { 'value' }
  let(:aggregate_operation) { 'count' }
  let(:aggregate_attribute) { nil }
  let(:display_percent) { false }

  before { allow(models).to receive(:column_alias_for) { |arg| Search::Save.all.send(:column_alias_for, arg) } }

  describe '#raw_data' do
    subject { chart.raw_data }

    context 'when #group_by_attribute is "some_attribute"' do
      it do
        expect(models).to receive(:group).with('some_attribute').and_return(models)
        expect(models).to receive(:order).with(count_id: :desc).and_return(models)
        expect(models).to receive(:limit).with(10).and_return(models)
        expect(models).to receive(:count).with(:id)
        subject
      end

      context 'when #first is true' do
        let(:first) { true }

        it do
          expect(models).to receive(:group).with('some_attribute').and_return(models)
          expect(models).to receive(:order).with(count_id: :asc).and_return(models)
          expect(models).to receive(:limit).with(10).and_return(models)
          expect(models).to receive(:count).with(:id)
          subject
        end
      end

      context 'when #top_count is 100' do
        let(:top_count) { 100 }

        it do
          expect(models).to receive(:group).with('some_attribute').and_return(models)
          expect(models).to receive(:order).with(count_id: :desc).and_return(models)
          expect(models).to receive(:limit).with(100).and_return(models)
          expect(models).to receive(:count).with(:id)
          subject
        end
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to receive(:group).with('some_attribute').and_return(models)
          expect(models).to receive(:order).with('some_attribute' => :desc).and_return(models)
          expect(models).to receive(:limit).with(10).and_return(models)
          expect(models).to receive(:count).with(:id)
          subject
        end
      end
    end

    context 'when #group_by_attribute is "date"' do
      let(:group_by_attribute) { 'date' }

      it do
        expect(models).to receive(:group_by_day).with(:created_at, last: 10).and_return(models)
        expect(models).to receive(:count).with(:id)
        subject
      end

      context 'when #first is true' do
        let(:first) { true }

        it do
          expect(models).to receive(:group_by_day).with(:created_at, last: 10).and_return(models)
          expect(models).to receive(:count).with(:id)
          subject
        end
      end

      context 'when #top_count is 100' do
        let(:top_count) { 100 }

        it do
          expect(models).to receive(:group_by_day).with(:created_at, last: 100).and_return(models)
          expect(models).to receive(:count).with(:id)
          subject
        end
      end
    end

    context 'when #group_by_attribute is "hour_of_day"' do
      let(:group_by_attribute) { 'hour_of_day' }

      it do
        expect(models).to receive(:group_by_hour_of_day).with(:created_at, {}).and_return(models)
        expect(models).to receive(:count).with(:id)
        subject
      end
    end

    context 'when #group_by_attribute is "day_of_week"' do
      let(:group_by_attribute) { 'day_of_week' }

      it do
        expect(models).to receive(:group_by_day_of_week).with(:created_at, {}).and_return(models)
        expect(models).to receive(:count).with(:id)
        subject
      end
    end

    context 'when #group_by_attribute needs inclusions and select' do
      let(:group_by_attribute) { 'custom_label_attribute' }

      it do
        expect(models).to(
          receive(:joins).with({ relation: { other_relation: {} }, another_relation: {} }).and_return(models)
        )
        expect(models).to(
          receive(:select).with('other_relations.name', 'another_relations.label').and_return(models)
        )
        expect(models).to(
          receive(:group).with('custom_label_attribute', 'other_relations.name', 'another_relations.label') \
                         .and_return(models)
        )
        expect(models).to receive(:order).with(count_id: :desc).and_return(models)
        expect(models).to receive(:limit).with(10).and_return(models)
        expect(models).to receive(:count).with(:id)
        subject
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to(
            receive(:joins).with({ relation: { other_relation: {} }, another_relation: {} }).and_return(models)
          )
          expect(models).to(
            receive(:select).with('other_relations.name', 'another_relations.label').and_return(models)
          )
          expect(models).to(
            receive(:group).with('custom_label_attribute', 'other_relations.name', 'another_relations.label')\
                           .and_return(models)
          )
          expect(models).to(
            receive(:order).with('other_relations.name' => :desc, 'another_relations.label' => :desc).and_return(models)
          )
          expect(models).to receive(:limit).with(10).and_return(models)
          expect(models).to receive(:count).with(:id)
          subject
        end
      end
    end

    context 'when #aggregate_operation is "sum"' do
      let(:aggregate_operation) { 'sum' }
      let(:aggregate_attribute) { 'EXTRACT(EPOCH FROM updated_at - created_at)' }

      it do
        expect(models).to receive(:group).with('some_attribute').and_return(models)
        expect(models).to(
          receive(:order).with('sum_extract_epoch_from_updated_at_created_at' => :desc).and_return(models)
        )
        expect(models).to receive(:limit).with(10).and_return(models)
        expect(models).to receive(:sum).with('EXTRACT(EPOCH FROM updated_at - created_at)')
        subject
      end
    end
  end

  describe '#data' do
    subject { chart.data }

    let(:raw_data) { {} }

    before { expect(chart).to receive(:raw_data).and_return(raw_data) }

    context 'when #group_by_attribute is "some_attribute"' do
      let(:raw_data) { { 'A' => 1, 'C' => 2 } }

      it 'returns data as is' do
        is_expected.to eq(raw_data)
      end
    end

    context 'when #group_by_attribute is "hour_of_day"' do
      let(:group_by_attribute) { 'hour_of_day' }
      let(:raw_data) { { 5 => 4, 13 => 42 } }

      it 'adds all missing hours' do # rubocop:disable Metrics/BlockLength
        is_expected.to eq(
          {
            0 => 0,
            1 => 0,
            2 => 0,
            3 => 0,
            4 => 0,
            5 => 4,
            6 => 0,
            7 => 0,
            8 => 0,
            9 => 0,
            10 => 0,
            11 => 0,
            12 => 0,
            13 => 42,
            14 => 0,
            15 => 0,
            16 => 0,
            17 => 0,
            18 => 0,
            19 => 0,
            20 => 0,
            21 => 0,
            22 => 0,
            23 => 0
          }
        )
      end
    end

    context 'when #group_by_attribute is "days_of_week"' do
      let(:group_by_attribute) { 'day_of_week' }
      let(:raw_data) { { 2 => 4, 5 => 42 } }

      it 'adds all missing days and labels keys' do
        is_expected.to eq(
          {
            I18n.t('date.day_names')[0] => 0,
            I18n.t('date.day_names')[1] => 0,
            I18n.t('date.day_names')[2] => 4,
            I18n.t('date.day_names')[3] => 0,
            I18n.t('date.day_names')[4] => 0,
            I18n.t('date.day_names')[5] => 42,
            I18n.t('date.day_names')[6] => 0
          }
        )
      end
    end

    context 'when #group_by_attribute needs more keys' do
      let(:group_by_attribute) { 'more_keys_attribute' }
      let(:raw_data) { { 'key2' => 42 } }

      it 'adds missing keys' do
        is_expected.to eq({ 'key1' => 0, 'key2' => 42, 'key3' => 0 })
      end
    end

    context 'when #group_by_attribute labels keys' do
      let(:group_by_attribute) { 'label_key_attribute' }
      let(:raw_data) { { 'key_to_label' => 42 } }

      it 'labels keys' do
        is_expected.to eq({ 'lebal_ot_yek' => 42 })
      end
    end

    context 'when #display_percent is true' do
      let(:display_percent) { true }
      let(:raw_data) { { '1' => 1, '2' => 3, '3' => 0 } }

      it 'computes percents' do
        is_expected.to eq({ '1' => 25, '2' => 75, '3' => 0 })
      end

      context 'when data is all 0' do
        let(:raw_data) { { '1' => 0, '2' => 0, '3' => 0 } }

        it 'computes percents' do
          is_expected.to eq({ '1' => 0, '2' => 0, '3' => 0 })
        end
      end
    end
  end

  describe '#to_chartkick' do
    subject { chart.to_chartkick(view_context) }

    let(:view_context) { double }
    let(:data) { double }

    before { allow(chart).to receive(:data).and_return(data) }

    context 'when #type is line' do
      it do
        expect(view_context).to receive(:line_chart).with(data, {})
        subject
      end

      context 'when #group_by_attribute is "hour_of_day"' do
        let(:group_by_attribute) { 'hour_of_day' }

        it do
          expect(view_context).to receive(:line_chart).with(data, xmin: 0, xmax: 23)
          subject
        end
      end

      context 'when #group_by_attribute is "day_of_week"' do
        let(:group_by_attribute) { 'day_of_week' }

        it do
          expect(view_context).to receive(:line_chart).with(data, xmin: 0, xmax: 6)
          subject
        end
      end

      context 'with #display_percent is true' do
        let(:display_percent) { true }

        it do
          expect(view_context).to receive(:line_chart).with(data, suffix: '%')
          subject
        end
      end
    end

    context 'when #type is pie' do
      let(:chart_type) { 'pie' }

      it do
        expect(view_context).to receive(:pie_chart).with(data, {})
        subject
      end
    end

    context 'when #type is column' do
      let(:chart_type) { 'column' }

      it do
        expect(view_context).to receive(:column_chart).with(data, {})
        subject
      end
    end
  end
end
