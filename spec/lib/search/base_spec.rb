# frozen_string_literal: true

RSpec.describe Search::Base, type: :model do
  class self::Search < Search::Base # rubocop:disable Lint/ConstantDefinitionInBlock,Style/ClassAndModuleChildren
    attribute :name
    attribute :start_at
    attribute :end_at

    period :period, :start_at, :end_at, chart_attributes: %i[created_at]

    attr_accessor :context

    class Order < ::Search::Order
      attribute :name, column: 'column'
      attr_accessor :context
    end

    class Chart < ::Search::Base::Chart
      group_by_attribute 'some_attribute', :string
      group_by_attribute 'some_numeric_attribute', :numeric
      group_by_attribute 'created_at', :datetime, sub_types: %i[by_week by_month hour_of_day day_of_week]
      aggregate_attribute 'some_numeric_attribute'
    end
  end

  let(:scope) { double }
  subject(:search) { self.class::Search.new }

  describe 'validations' do
    describe 'period' do
      context 'when period is not valid' do
        before { allow(search).to receive(:period).and_return(double(valid?: false)) }
        it { is_expected.to_not be_valid }
      end

      context 'when period is valid' do
        before { allow(search).to receive(:period).and_return(double(valid?: true)) }
        it { is_expected.to be_valid }
      end
    end

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

    it { is_expected.to allow_value(nil).for(:group_by_attribute) }
    it { is_expected.to allow_value('').for(:group_by_attribute) }

    context 'when chart_type is present' do
      before { search.chart_type = 'line' }

      it { is_expected.to allow_value('some_attribute').for(:group_by_attribute) }
      it { is_expected.to allow_value('some_numeric_attribute').for(:group_by_attribute) }
      it { is_expected.to allow_value('created_at').for(:group_by_attribute) }
      it { is_expected.to allow_value('created_at_by_week').for(:group_by_attribute) }
      it { is_expected.to allow_value('created_at_by_month').for(:group_by_attribute) }
      it { is_expected.to allow_value('created_at_hour_of_day').for(:group_by_attribute) }
      it { is_expected.to allow_value('created_at_day_of_week').for(:group_by_attribute) }
      it { is_expected.not_to allow_value(nil).for(:group_by_attribute) }
      it { is_expected.not_to allow_value('').for(:group_by_attribute) }
      it { is_expected.not_to allow_value('some_other_attribute').for(:group_by_attribute) }

      it { is_expected.to allow_value(10).for(:top_count) }
      it { is_expected.to allow_value('10').for(:top_count) }
      it { is_expected.not_to allow_value(nil).for(:top_count) }
      it { is_expected.not_to allow_value('').for(:top_count) }
      it { is_expected.not_to allow_value(-1).for(:top_count) }
      it { is_expected.not_to allow_value(1).for(:top_count) }

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

      it { is_expected.to allow_value('some_attribute').for(:subgroup_by_attribute) }
      it { is_expected.to allow_value('some_numeric_attribute').for(:subgroup_by_attribute) }
      it { is_expected.to allow_value('created_at').for(:subgroup_by_attribute) }
      it { is_expected.to allow_value('created_at_by_week').for(:subgroup_by_attribute) }
      it { is_expected.to allow_value('created_at_by_month').for(:subgroup_by_attribute) }
      it { is_expected.to allow_value('created_at_hour_of_day').for(:subgroup_by_attribute) }
      it { is_expected.to allow_value('created_at_day_of_week').for(:subgroup_by_attribute) }
      it { is_expected.to allow_value(nil).for(:subgroup_by_attribute) }
      it { is_expected.to allow_value('').for(:subgroup_by_attribute) }
      it { is_expected.not_to allow_value('some_other_attribute').for(:subgroup_by_attribute) }

      context 'when chart_type is "pie"' do
        before { search.chart_type = 'pie' }

        it { is_expected.not_to allow_value('some_attribute').for(:subgroup_by_attribute) }
        it { is_expected.to allow_value(nil).for(:subgroup_by_attribute) }
        it { is_expected.to allow_value('').for(:subgroup_by_attribute) }
      end

      context 'when subgroup_by_attribute is filled' do
        before { search.subgroup_by_attribute = 'some_attribute' }

        it { is_expected.to allow_value(10).for(:subgroup_top_count) }
        it { is_expected.to allow_value('10').for(:subgroup_top_count) }
        it { is_expected.not_to allow_value(nil).for(:subgroup_top_count) }
        it { is_expected.not_to allow_value('').for(:subgroup_top_count) }
        it { is_expected.not_to allow_value(-1).for(:subgroup_top_count) }
        it { is_expected.not_to allow_value(1).for(:subgroup_top_count) }
      end
    end
  end

  describe '.period' do
    subject { search.period }

    let(:start_at) { Time.zone.yesterday }
    let(:end_at) { Time.zone.tomorrow }

    before do
      search.start_at = start_at
      search.end_at = end_at
    end

    context 'when both start_at and end_at are not filled' do
      let(:start_at) { nil }
      let(:end_at) { nil }

      it { is_expected.to be_nil }
    end

    context 'when only start_at is filled' do
      let(:end_at) { nil }

      it { is_expected.to eq(start_at..) }
    end

    context 'when both start_at and end_at are not filled' do
      let(:start_at) { nil }

      it { is_expected.to eq(..end_at) }
    end

    context 'when both start_at and end_at are filled' do
      it { is_expected.to eq(start_at..end_at) }
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

        expect(scope).to receive(:paginate).with({ per_page: 42, page: 7 }).and_return(scope)

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

    before do
      allow(search).to receive(:search).and_return(scope)

      search.chart_type = 'line'
      search.group_by_attribute = 'some_attribute'
      search.first = true
      search.top_count = 100
      search.sort_by = 'label'
      search.aggregate_operation = 'sum'
      search.aggregate_attribute = 'some_numeric_attribute'
      search.display_percent = true
      search.subgroup_by_attribute = 'some_attribute'
      search.subgroup_first = true
      search.subgroup_top_count = 10
    end

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
      it do
        chart = double
        expect(self.class::Search::Chart).to receive(:new).with(
          scope,
          type: 'line',
          group_by_attribute: 'some_attribute',
          first: true,
          top_count: 100,
          sort_by: 'label',
          aggregate_operation: 'sum',
          aggregate_attribute: 'some_numeric_attribute',
          display_percent: true,
          subgroup_by_attribute: 'some_attribute',
          subgroup_first: true,
          subgroup_top_count: 10,
          period: nil,
          subgroup_period: nil
        ).and_return(chart)
        is_expected.to eq(chart)
      end

      context 'when #group_by_attribute is a datetime' do
        before { search.group_by_attribute = 'created_at' }

        it do
          chart = double
          expect(self.class::Search::Chart).to receive(:new).with(
            scope,
            type: 'line',
            group_by_attribute: 'created_at',
            first: true,
            top_count: 100,
            sort_by: 'label',
            aggregate_operation: 'sum',
            aggregate_attribute: 'some_numeric_attribute',
            display_percent: true,
            subgroup_by_attribute: 'some_attribute',
            subgroup_first: true,
            subgroup_top_count: 10,
            period: nil,
            subgroup_period: nil
          ).and_return(chart)
          is_expected.to eq(chart)
        end

        context 'when search filters on that attribute' do
          let(:start_at) { Time.zone.yesterday }
          let(:end_at) { Time.zone.tomorrow }

          before do
            search.start_at = start_at
            search.end_at = end_at
          end

          it do
            chart = double
            expect(self.class::Search::Chart).to receive(:new).with(
              scope,
              type: 'line',
              group_by_attribute: 'created_at',
              first: true,
              top_count: 100,
              sort_by: 'label',
              aggregate_operation: 'sum',
              aggregate_attribute: 'some_numeric_attribute',
              display_percent: true,
              subgroup_by_attribute: 'some_attribute',
              subgroup_first: true,
              subgroup_top_count: 10,
              period: Period.new(from: start_at, to: end_at),
              subgroup_period: nil
            ).and_return(chart)
            is_expected.to eq(chart)
          end
        end
      end

      context 'when #group_by_attribute is a datetime grouped by week' do
        before { search.group_by_attribute = 'created_at_by_week' }

        context 'when search filters on that attribute' do
          let(:start_at) { Time.zone.yesterday }
          let(:end_at) { Time.zone.tomorrow }

          before do
            search.start_at = start_at
            search.end_at = end_at
          end

          it do
            chart = double
            expect(self.class::Search::Chart).to receive(:new).with(
              scope,
              type: 'line',
              group_by_attribute: 'created_at_by_week',
              first: true,
              top_count: 100,
              sort_by: 'label',
              aggregate_operation: 'sum',
              aggregate_attribute: 'some_numeric_attribute',
              display_percent: true,
              subgroup_by_attribute: 'some_attribute',
              subgroup_first: true,
              subgroup_top_count: 10,
              period: Period.new(from: start_at, to: end_at),
              subgroup_period: nil
            ).and_return(chart)
            is_expected.to eq(chart)
          end
        end
      end

      context 'when #group_by_attribute is a datetime grouped by month' do
        before { search.group_by_attribute = 'created_at_by_month' }

        context 'when search filters on that attribute' do
          let(:start_at) { Time.zone.yesterday }
          let(:end_at) { Time.zone.tomorrow }

          before do
            search.start_at = start_at
            search.end_at = end_at
          end

          it do
            chart = double
            expect(self.class::Search::Chart).to receive(:new).with(
              scope,
              type: 'line',
              group_by_attribute: 'created_at_by_month',
              first: true,
              top_count: 100,
              sort_by: 'label',
              aggregate_operation: 'sum',
              aggregate_attribute: 'some_numeric_attribute',
              display_percent: true,
              subgroup_by_attribute: 'some_attribute',
              subgroup_first: true,
              subgroup_top_count: 10,
              period: Period.new(from: start_at, to: end_at),
              subgroup_period: nil
            ).and_return(chart)
            is_expected.to eq(chart)
          end
        end
      end

      context 'when #subgroup_by_attribute is a datetime' do
        before { search.subgroup_by_attribute = 'created_at' }

        context 'when search filters on that attribute' do
          let(:start_at) { Time.zone.yesterday }
          let(:end_at) { Time.zone.tomorrow }

          before do
            search.start_at = start_at
            search.end_at = end_at
          end

          it do
            chart = double
            expect(self.class::Search::Chart).to receive(:new).with(
              scope,
              type: 'line',
              group_by_attribute: 'some_attribute',
              first: true,
              top_count: 100,
              sort_by: 'label',
              aggregate_operation: 'sum',
              aggregate_attribute: 'some_numeric_attribute',
              display_percent: true,
              subgroup_by_attribute: 'created_at',
              subgroup_first: true,
              subgroup_top_count: 10,
              period: nil,
              subgroup_period: Period.new(from: start_at, to: end_at)
            ).and_return(chart)
            is_expected.to eq(chart)
          end
        end
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

  describe '#scope' do
    subject(:scope) { search.scope(initial_scope) }

    let(:initial_scope) { double(:initial_scope) }

    it 'returns initial scope unchanged' do
      is_expected.to eq(initial_scope)
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
    group_by_attribute 'some_attribute', :string
    group_by_attribute 'some_other_attribute', :string
    group_by_attribute 'some_numeric_attribute', :numeric
    group_by_attribute 'created_at',
                       :datetime,
                       sub_types: %i[by_week by_month hour_of_day day_of_week hour_of_day day_of_week]
    group_by_attribute 'date', :date, sub_types: %i[by_week by_month day_of_week]
    group_by_attribute 'complex_select_attribute', :string, selects: ['CASE WHEN 1 "true" ELSE "false" END']
    group_by_attribute 'custom_label_attribute',
                       :string,
                       joins: { relation: { other_relation: {} }, another_relation: {} },
                       selects: %w[other_relations.name another_relations.label] do
      def label(key)
        "#{key[0]} (#{key[1]})"
      end
    end
    group_by_attribute 'custom_label_attribute_b',
                       :string,
                       joins: { relation_b: { other_relation_b: {} }, another_relation_b: {} },
                       selects: %w[other_relation_bs.name another_relation_bs.label] do
      def nil_key?(key)
        key[0].nil?
      end

      def label(key)
        "#{key[0]} [#{key[1]}]"
      end
    end
    group_by_attribute 'custom_label_numeric_attribute', :numeric, sortable: :before_label do
      def label(key)
        "Level #{key}"
      end
    end
    group_by_attribute 'more_keys_attribute', :numeric, keys: [2, 3, 1]
    group_by_attribute 'more_keys_attribute_b', :string, keys: %w[A B C]
    group_by_attribute 'sortable_label_key_attribute', :string do
      def label(key)
        key.reverse
      end
    end
    group_by_attribute 'sortable_label_key_attribute_b', :string, selects: %w[name] do
      def label(key)
        key.reverse
      end
    end
    group_by_attribute 'non_sortable_label_key_attribute', :string, sortable: false do
      def label(key)
        key.reverse
      end
    end
    group_by_attribute 'custom_label_attribute',
                       :string,
                       joins: { relation: { other_relation: {} }, another_relation: {} },
                       selects: %w[other_relations.name another_relations.label] do
      def label(key)
        "#{key[0]} (#{key[1]})"
      end
    end
    group_by_attribute 'custom_label_attribute_b',
                       :string,
                       joins: { relation_b: { other_relation_b: {} }, another_relation_b: {} },
                       selects: %w[other_relation_bs.name another_relation_bs.label] do
      def nil_key?(key)
        key[0].nil?
      end

      def label(key)
        "#{key[0]} [#{key[1]}]"
      end
    end
    group_by_attribute 'label_series_attribute', :numeric, sortable: :before_label do
      def label_series(key)
        "Level #{key}"
      end
    end

    aggregate_attribute 'some_numeric_attribute'
    aggregate_attribute 'custom_aggregate_attribute', 'EXTRACT(EPOCH FROM updated_at - created_at)'
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
      display_percent: display_percent,
      subgroup_by_attribute: subgroup_by_attribute,
      subgroup_first: subgroup_first,
      subgroup_top_count: subgroup_top_count,
      period: period,
      subgroup_period: subgroup_period
    )
  end
  let(:models) do
    connection = double(:connection, adapter_name: ActiveRecord::Base.connection.adapter_name)
    allow(connection).to receive(:quote) { |v| ActiveRecord::Base.connection.quote(v) }
    allow(connection).to receive(:quote_column_name) { |v| ActiveRecord::Base.connection.quote_column_name(v) }
    models = double(
      :models,
      klass: double(:klass),
      table_name: 'public.models',
      quoted_table_name: '"public"."models"',
      primary_key: 'id',
      connection: connection
    )
    allow(connection).to receive(:table_alias_for) { |table_name| Search::Save.connection.table_alias_for(table_name) }
    models
  end
  let(:chart_type) { 'line' }
  let(:group_by_attribute) { 'some_attribute' }
  let(:first) { false }
  let(:top_count) { 10 }
  let(:sort_by) { 'value' }
  let(:aggregate_operation) { 'count' }
  let(:aggregate_attribute) { nil }
  let(:display_percent) { false }
  let(:subgroup_by_attribute) { nil }
  let(:subgroup_first) { false }
  let(:subgroup_top_count) { 5 }
  let(:period) { nil }
  let(:subgroup_period) { nil }

  let(:expected_groupdate_options) { nil }

  before do
    if expected_groupdate_options
      groupdate_column = double(:groupdate_column)
      allow(Groupdate::Magic::Relation).to receive(:resolve_column).and_return(groupdate_column)
      expect(Groupdate.adapters[models.connection.adapter_name]).to(
        receive(:new).with(models, include({ column: groupdate_column }.merge(expected_groupdate_options)))
                     .at_least(1)
                     .and_return(
                       double(
                         :groupdate_adapter,
                         where_clause: ['MOCK_GROUPDATE_WHERE_CLAUSE'],
                         group_clause: 'MOCK_GROUPDATE_GROUP_CLAUSE'
                       )
                     )
      )
    end
  end

  # rubocop:disable Style/WordArray
  describe '#xaxis' do
    subject { chart.xaxis }

    let(:group_by_attribute) { 'some_other_attribute' }

    context 'with a simple string attribute' do
      let(:group_by_attribute) { 'some_attribute' }
      let(:subgroup_by_attribute) { 'some_other_attribute' }

      it do
        expect(models).to receive(:group).with('some_attribute').and_return(models)
        expect(models).to receive(:order).with({ count_id: :desc, 'some_attribute' => :desc }).and_return(models)
        expect(models).to receive(:limit).with(10).and_return(models)
        expect(models).to receive(:count).with(:id).and_return({ 'A' => 1, 'B' => 0 })
        is_expected.to eq(['A', 'B'])
      end

      context 'when #first is true' do
        let(:first) { true }

        it do
          expect(models).to receive(:group).and_return(models)
          expect(models).to receive(:order).with({ count_id: :asc, 'some_attribute' => :asc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
          subject
        end
      end

      context 'when #subgroup_first is true' do
        let(:subgroup_first) { true }

        it do
          expect(models).to receive(:group).and_return(models)
          expect(models).to receive(:order).with({ count_id: :desc, 'some_attribute' => :desc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
          subject
        end
      end

      context 'when #aggregate_operation is "sum"' do
        let(:aggregate_operation) { 'sum' }
        let(:aggregate_attribute) { 'some_numeric_attribute' }

        it do
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:order).with({ 'sum_some_numeric_attribute' => :desc, 'some_attribute' => :desc })
                           .and_return(models)
          )
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:sum).with('some_numeric_attribute').and_return({ 'A' => 1, 'B' => 0 })
          subject
        end
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to receive(:select).with('some_attribute AS some_attribute').and_return(models)
          expect(models).to receive(:group).with('some_attribute').and_return(models)
          expect(models).to receive(:order).with({ 'some_attribute' => :desc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models.connection).to receive(:select_values).with(models)
          subject
        end

        context 'when #first is true' do
          let(:first) { true }

          it do
            expect(models).to receive(:select).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).with({ 'some_attribute' => :asc }).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models.connection).to receive(:select_values).with(models)
            subject
          end
        end

        context 'when #subgroup_first is true' do
          let(:subgroup_first) { true }

          it do
            expect(models).to receive(:select).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).with({ 'some_attribute' => :desc }).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models.connection).to receive(:select_values).with(models)
            subject
          end
        end
      end
    end

    # #xaxis is never called for attributes having #compute_series_xaxis? being false (continuous or non-sortable)

    context 'with an attribute needing inclusions and select' do
      let(:group_by_attribute) { 'custom_label_attribute' }

      it do
        expect(models).to(
          receive(:left_outer_joins).with({ relation: { other_relation: {} }, another_relation: {} })
                                    .and_return(models)
        )
        expect(models).to receive(:select).with('other_relations.name', 'another_relations.label').and_return(models)
        expect(models).to receive(:group).with('other_relations.name', 'another_relations.label').and_return(models)
        expect(models).to(
          receive(:order).with({ count_id: :desc, 'other_relations_name' => :desc, 'another_relations_label' => :desc })
                         .and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
        subject
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to(
            receive(:left_outer_joins).with({ relation: { other_relation: {} }, another_relation: {} })
                                      .and_return(models)
          )
          expect(models).to(
            receive(:select).with(
              'other_relations.name AS other_relations_name',
              'another_relations.label AS another_relations_label'
            ).and_return(models)
          )
          expect(models).to receive(:group).with('other_relations.name', 'another_relations.label').and_return(models)
          expect(models).to(
            receive(:order).with({ 'other_relations_name' => :desc, 'another_relations_label' => :desc })
                           .and_return(models)
          )
          expect(models).to receive(:limit).and_return(models)
          expect(models.connection).to receive(:select_rows).with(models)
          subject
        end

        context 'when #first is true' do
          let(:first) { true }

          it do
            expect(models).to receive(:left_outer_joins).and_return(models)
            expect(models).to receive(:select).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to(
              receive(:order).with({ 'other_relations_name' => :asc, 'another_relations_label' => :asc })
                             .and_return(models)
            )
            expect(models).to receive(:limit).and_return(models)
            expect(models.connection).to receive(:select_rows).with(models)
            subject
          end
        end
      end
    end
  end

  describe '#series' do
    subject { chart.series }

    let(:group_by_attribute) { 'some_attribute' }
    let(:xaxis) { ['A', 'B', nil] }

    before do
      if xaxis
        expect(chart).to receive(:xaxis).at_least(1).and_return(xaxis)
      else
        expect(chart).not_to receive(:xaxis)
      end
    end

    context 'with a simple string attribute' do
      let(:group_by_attribute) { 'some_other_attribute' }
      let(:subgroup_by_attribute) { 'some_attribute' }

      it do
        expect(models).to(
          receive(:where).with(
            [
              "(some_other_attribute = 'A')",
              "(some_other_attribute = 'B')",
              '(some_other_attribute IS NULL)'
            ].join(' OR ')
          ).and_return(models)
        )
        expect(models).to receive(:group).with('some_attribute').and_return(models)
        expect(models).to receive(:order).with({ count_id: :desc, 'some_attribute' => :desc }).and_return(models)
        expect(models).to receive(:limit).with(5).and_return(models)
        expect(models).to receive(:count).with(:id).and_return({ 'A' => 1, 'B' => 0 })
        is_expected.to eq(['A', 'B'])
      end

      context 'when #first is true' do
        let(:first) { true }

        it do
          expect(models).to receive(:where).and_return(models)
          expect(models).to receive(:group).and_return(models)
          expect(models).to receive(:order).with({ count_id: :asc, 'some_attribute' => :desc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
          subject
        end
      end

      context 'when #subgroup_first is true' do
        let(:subgroup_first) { true }

        it do
          expect(models).to receive(:where).and_return(models)
          expect(models).to receive(:group).and_return(models)
          expect(models).to receive(:order).with({ count_id: :desc, 'some_attribute' => :asc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
          subject
        end
      end

      context 'when xaxis is empty' do
        let(:xaxis) { [] }

        it do
          expect(models).to receive(:none).and_return(models)
          expect(models).to receive(:group).with('some_attribute').and_return(models)
          expect(models).to receive(:order).with({ count_id: :desc, 'some_attribute' => :desc }).and_return(models)
          expect(models).to receive(:limit).with(5).and_return(models)
          expect(models).to receive(:count).with(:id).and_return({})
          is_expected.to eq([])
        end
      end

      context 'when #aggregate_operation is "sum"' do
        let(:aggregate_operation) { 'sum' }
        let(:aggregate_attribute) { 'some_numeric_attribute' }

        it do
          expect(models).to receive(:where).and_return(models)
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:order).with({ 'sum_some_numeric_attribute' => :desc, 'some_attribute' => :desc })
                           .and_return(models)
          )
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:sum).with('some_numeric_attribute').and_return({ 'A' => 1, 'B' => 0 })
          is_expected.to eq(['A', 'B'])
        end
      end

      context 'when #group_by_attribute is' do
        context 'a numeric attribute' do
          let(:group_by_attribute) { 'some_numeric_attribute' }
          let(:xaxis) { nil }

          it do
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
            subject
          end

          context 'with keys' do
            let(:group_by_attribute) { 'more_keys_attribute' }
            let(:xaxis) { [1, 2, nil] }

            it do
              expect(models).to(
                receive(:where).with(
                  [
                    '(more_keys_attribute = 1)',
                    '(more_keys_attribute = 2)',
                    '(more_keys_attribute IS NULL)'
                  ].join(' OR ')
                ).and_return(models)
              )
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
              subject
            end
          end
        end

        context 'a datetime attribute' do
          let(:group_by_attribute) { 'created_at' }
          let(:expected_groupdate_options) do
            { period: :day, time_zone: have_attributes(name: Time.zone.name), time_range: be_present }
          end
          let(:xaxis) { nil }

          it do
            expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
            subject
          end

          context 'with period' do
            let(:period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

            it do
              expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
              subject
            end
          end
        end

        context 'a datetime attribute grouped by week' do
          let(:group_by_attribute) { 'created_at_by_week' }
          let(:expected_groupdate_options) do
            { period: :week, time_zone: have_attributes(name: Time.zone.name), time_range: be_present }
          end
          let(:xaxis) { nil }

          it do
            expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
            subject
          end
        end

        context 'a datetime attribute grouped by month' do
          let(:group_by_attribute) { 'created_at_by_month' }
          let(:expected_groupdate_options) do
            { period: :month, time_zone: have_attributes(name: Time.zone.name), time_range: be_present }
          end
          let(:xaxis) { nil }

          it do
            expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
            subject
          end
        end

        context 'a datetime attribute grouped by hour of day' do
          let(:group_by_attribute) { 'created_at_hour_of_day' }
          let(:expected_groupdate_options) do
            { period: :hour_of_day, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
          end
          let(:xaxis) { nil }

          it do
            expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
            subject
          end

          context 'with period' do
            let(:period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

            it do
              expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
              subject
            end
          end
        end

        context 'a datetime attribute grouped by day of week' do
          let(:group_by_attribute) { 'created_at_day_of_week' }
          let(:expected_groupdate_options) do
            { period: :day_of_week, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
          end
          let(:xaxis) { nil }

          it do
            expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
            subject
          end
        end

        context 'a date attribute' do
          let(:group_by_attribute) { 'date' }
          let(:expected_groupdate_options) do
            { period: :day, time_zone: have_attributes(name: 'Etc/UTC'), time_range: be_present }
          end
          let(:xaxis) { nil }

          it do
            expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
            subject
          end

          context 'with period' do
            let(:period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

            it do
              expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
              subject
            end
          end
        end

        context 'a date attribute grouped by week' do
          let(:group_by_attribute) { 'date_by_week' }
          let(:expected_groupdate_options) do
            { period: :week, time_zone: have_attributes(name: 'Etc/UTC'), time_range: be_present }
          end
          let(:xaxis) { nil }

          it do
            expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
            subject
          end
        end

        context 'a date attribute grouped by month' do
          let(:group_by_attribute) { 'date_by_month' }
          let(:expected_groupdate_options) do
            { period: :month, time_zone: have_attributes(name: 'Etc/UTC'), time_range: be_present }
          end
          let(:xaxis) { nil }

          it do
            expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
            subject
          end
        end

        context 'a date attribute grouped by day of week' do
          let(:group_by_attribute) { 'date_day_of_week' }
          let(:expected_groupdate_options) do
            { period: :day_of_week, time_zone: have_attributes(name: 'Etc/UTC'), time_range: nil }
          end
          let(:xaxis) { nil }

          it do
            expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
            subject
          end

          context 'with period' do
            let(:period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

            it do
              expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
              subject
            end
          end
        end

        context 'a non-sortable attribute' do
          let(:group_by_attribute) { 'non_sortable_label_key_attribute' }
          let(:xaxis) { nil }

          it do
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count).and_return({ 'A' => 1, 'B' => 0 })
            subject
          end
        end
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to receive(:select).with('some_attribute AS some_attribute').and_return(models)
          expect(models).to(
            receive(:where).with(
              [
                "(some_other_attribute = 'A')",
                "(some_other_attribute = 'B')",
                '(some_other_attribute IS NULL)'
              ].join(' OR ')
            ).and_return(models)
          )
          expect(models).to receive(:group).with('some_attribute').and_return(models)
          expect(models).to receive(:order).with({ 'some_attribute' => :desc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models.connection).to receive(:select_values).with(models)
          subject
        end

        context 'when #first is true' do
          let(:first) { true }

          it do
            expect(models).to receive(:select).and_return(models)
            expect(models).to receive(:where).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).with({ 'some_attribute' => :desc }).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models.connection).to receive(:select_values).with(models)
            subject
          end
        end

        context 'when #subgroup_first is true' do
          let(:subgroup_first) { true }

          it do
            expect(models).to receive(:select).and_return(models)
            expect(models).to receive(:where).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).with({ 'some_attribute' => :asc }).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models.connection).to receive(:select_values).with(models)
            subject
          end
        end

        context 'when #group_by_attribute is' do
          context 'a numeric attribute' do
            let(:group_by_attribute) { 'some_numeric_attribute' }
            let(:xaxis) { nil }

            it do
              expect(models).to receive(:select).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models.connection).to receive(:select_values).with(models)
              subject
            end

            context 'with keys' do
              let(:group_by_attribute) { 'more_keys_attribute' }
              let(:xaxis) { [1, 2, nil] }

              it do
                expect(models).to receive(:select).and_return(models)
                expect(models).to(
                  receive(:where).with(
                    [
                      '(more_keys_attribute = 1)',
                      '(more_keys_attribute = 2)',
                      '(more_keys_attribute IS NULL)'
                    ].join(' OR ')
                  ).and_return(models)
                )
                expect(models).to receive(:group).and_return(models)
                expect(models).to receive(:order).and_return(models)
                expect(models).to receive(:limit).and_return(models)
                expect(models.connection).to receive(:select_values).with(models)
                subject
              end
            end
          end

          context 'a datetime attribute' do
            let(:group_by_attribute) { 'created_at' }
            let(:expected_groupdate_options) do
              { period: :day, time_zone: have_attributes(name: Time.zone.name), time_range: be_present }
            end
            let(:xaxis) { nil }

            it do
              expect(models).to receive(:select).and_return(models)
              expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models.connection).to receive(:select_values).with(models)
              subject
            end
          end

          context 'a datetime attribute grouped by week' do
            let(:group_by_attribute) { 'created_at_by_week' }
            let(:expected_groupdate_options) do
              { period: :week, time_zone: have_attributes(name: Time.zone.name), time_range: be_present }
            end
            let(:xaxis) { nil }

            it do
              expect(models).to receive(:select).and_return(models)
              expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models.connection).to receive(:select_values).with(models)
              subject
            end
          end

          context 'a datetime attribute grouped by month' do
            let(:group_by_attribute) { 'created_at_by_month' }
            let(:expected_groupdate_options) do
              { period: :month, time_zone: have_attributes(name: Time.zone.name), time_range: be_present }
            end
            let(:xaxis) { nil }

            it do
              expect(models).to receive(:select).and_return(models)
              expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models.connection).to receive(:select_values).with(models)
              subject
            end
          end

          context 'a datetime attribute grouped by hour of day' do
            let(:group_by_attribute) { 'created_at_hour_of_day' }
            let(:expected_groupdate_options) do
              { period: :hour_of_day, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
            end
            let(:xaxis) { nil }

            it do
              expect(models).to receive(:select).and_return(models)
              expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models.connection).to receive(:select_values).with(models)
              subject
            end
          end

          context 'a datetime attribute grouped by day of week' do
            let(:group_by_attribute) { 'created_at_day_of_week' }
            let(:expected_groupdate_options) do
              { period: :day_of_week, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
            end
            let(:xaxis) { nil }

            it do
              expect(models).to receive(:select).and_return(models)
              expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models.connection).to receive(:select_values).with(models)
              subject
            end
          end

          context 'a date attribute' do
            let(:group_by_attribute) { 'date' }
            let(:expected_groupdate_options) do
              { period: :day, time_zone: have_attributes(name: 'Etc/UTC'), time_range: be_present }
            end
            let(:xaxis) { nil }

            it do
              expect(models).to receive(:select).and_return(models)
              expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models.connection).to receive(:select_values).with(models)
              subject
            end
          end

          context 'a date attribute grouped by week' do
            let(:group_by_attribute) { 'date_by_week' }
            let(:expected_groupdate_options) do
              { period: :week, time_zone: have_attributes(name: 'Etc/UTC'), time_range: be_present }
            end
            let(:xaxis) { nil }

            it do
              expect(models).to receive(:select).and_return(models)
              expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models.connection).to receive(:select_values).with(models)
              subject
            end
          end

          context 'a date attribute grouped by month' do
            let(:group_by_attribute) { 'date_by_month' }
            let(:expected_groupdate_options) do
              { period: :month, time_zone: have_attributes(name: 'Etc/UTC'), time_range: be_present }
            end
            let(:xaxis) { nil }

            it do
              expect(models).to receive(:select).and_return(models)
              expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models.connection).to receive(:select_values).with(models)
              subject
            end
          end

          context 'a date attribute grouped by day of week' do
            let(:group_by_attribute) { 'date_day_of_week' }
            let(:expected_groupdate_options) do
              { period: :day_of_week, time_zone: have_attributes(name: 'Etc/UTC'), time_range: nil }
            end
            let(:xaxis) { nil }

            it do
              expect(models).to receive(:select).and_return(models)
              expect(models).to receive(:where).with(['MOCK_GROUPDATE_WHERE_CLAUSE']).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models.connection).to receive(:select_values).with(models)
              subject
            end
          end

          context 'a non-sortable attribute' do
            let(:group_by_attribute) { 'non_sortable_label_key_attribute' }
            let(:xaxis) { nil }

            it do
              expect(models).to receive(:select).and_return(models)
              expect(models).to receive(:group).and_return(models)
              expect(models).to receive(:order).and_return(models)
              expect(models).to receive(:limit).and_return(models)
              expect(models.connection).to receive(:select_values).with(models)
              subject
            end
          end
        end
      end
    end

    context 'with a datetime attribute' do
      let(:subgroup_by_attribute) { 'created_at' }
      let(:expected_groupdate_options) do
        { period: :day, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
      end

      it do
        keys = [2.days.ago, 1.day.ago, Time.zone.now].map(&:to_date)
        expect(models).to receive(:where).and_return(models)
        expect(models).to(
          receive(:group_by_period).with(
            :day,
            'created_at',
            time_zone: Time.zone,
            last: nil,
            range: nil,
            series: false
          ).and_return(models)
        )
        expect(models).to(
          receive(:order).with({ count_id: :desc, 'mock_groupdate_group_clause' => :desc }).and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to receive(:count).and_return(double(keys: keys))
        subject
      end

      context 'with subgroup period' do
        let(:subgroup_period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }
        let(:expected_groupdate_options) do
          { period: :day, time_zone: have_attributes(name: Time.zone.name), time_range: be_present }
        end

        it do
          keys = [2.days.ago, 1.day.ago, Time.zone.now].map(&:to_date)
          expect(models).to receive(:where).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :day,
              'created_at',
              time_zone: Time.zone,
              last: nil,
              range: be_present,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count).and_return(double(keys: keys))
          subject
        end
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to(
            receive(:select).with('MOCK_GROUPDATE_GROUP_CLAUSE AS mock_groupdate_group_clause').and_return(models)
          )
          expect(models).to receive(:where).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :day,
              'created_at',
              time_zone: Time.zone,
              last: nil,
              range: nil,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:order).with({ 'mock_groupdate_group_clause' => :desc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models.connection).to receive(:select_values).with(models)
          subject
        end

        context 'with subgroup period' do
          let(:subgroup_period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }
          let(:expected_groupdate_options) do
            { period: :day, time_zone: have_attributes(name: Time.zone.name), time_range: be_present }
          end

          it do
            expect(models).to receive(:select).and_return(models)
            expect(models).to receive(:where).and_return(models)
            expect(models).to(
              receive(:group_by_period).with(
                :day,
                'created_at',
                time_zone: Time.zone,
                last: nil,
                range: be_present,
                series: false
              ).and_return(models)
            )
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models.connection).to receive(:select_values).with(models)
            subject
          end
        end
      end
    end

    context 'with a datetime attribute grouped by week' do
      let(:subgroup_by_attribute) { 'created_at_by_week' }
      let(:expected_groupdate_options) do
        { period: :week, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
      end

      it do
        keys = [2.weeks.ago, 1.week.ago, Time.zone.now].map(&:beginning_of_week).map(&:to_date)
        expect(models).to receive(:where).and_return(models)
        expect(models).to(
          receive(:group_by_period).with(
            :week,
            'created_at',
            time_zone: Time.zone,
            last: nil,
            range: nil,
            series: false
          ).and_return(models)
        )
        expect(models).to(
          receive(:order).with({ count_id: :desc, 'mock_groupdate_group_clause' => :desc }).and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to receive(:count).and_return(double(keys: keys))
        subject
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to(
            receive(:select).with('MOCK_GROUPDATE_GROUP_CLAUSE AS mock_groupdate_group_clause').and_return(models)
          )
          expect(models).to receive(:where).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :week,
              'created_at',
              time_zone: Time.zone,
              last: nil,
              range: nil,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:order).with({ 'mock_groupdate_group_clause' => :desc }).and_return(models)
          expect(models).to receive(:limit).with(5).and_return(models)
          expect(models.connection).to receive(:select_values).with(models)
          subject
        end
      end
    end

    context 'with a datetime attribute grouped by month' do
      let(:subgroup_by_attribute) { 'created_at_by_month' }
      let(:expected_groupdate_options) do
        { period: :month, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
      end

      it do
        expect(models).to receive(:where).and_return(models)
        keys = [2.months.ago, 1.month.ago, Time.zone.now].map(&:beginning_of_month).map(&:to_date)
        expect(models).to(
          receive(:group_by_period).with(
            :month,
            'created_at',
            time_zone: Time.zone,
            last: nil,
            range: nil,
            series: false
          ).and_return(models)
        )
        expect(models).to(
          receive(:order).with({ count_id: :desc, 'mock_groupdate_group_clause' => :desc }).and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to receive(:count).and_return(double(keys: keys))
        subject
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to(
            receive(:select).with('MOCK_GROUPDATE_GROUP_CLAUSE AS mock_groupdate_group_clause').and_return(models)
          )
          expect(models).to receive(:where).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :month,
              'created_at',
              time_zone: Time.zone,
              last: nil,
              range: nil,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:order).with({ 'mock_groupdate_group_clause' => :desc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models.connection).to receive(:select_values).with(models)
          subject
        end
      end
    end

    context 'with a datetime attribute by hour of day' do
      let(:subgroup_by_attribute) { 'created_at_hour_of_day' }
      let(:expected_groupdate_options) do
        { period: :hour_of_day, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
      end

      it do
        expect(models).to receive(:where).and_return(models)
        expect(models).to(
          receive(:group_by_period).with(
            :hour_of_day,
            'created_at',
            time_zone: Time.zone,
            last: nil,
            range: nil,
            series: false
          ).and_return(models)
        )
        expect(models).to(
          receive(:order).with({ count_id: :desc, 'mock_groupdate_group_clause' => :desc }).and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to receive(:count).and_return(double(keys: [1, 2, 3]))
        subject
      end

      context 'with subgroup period' do
        let(:subgroup_period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

        it do
          expect(models).to receive(:where).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :hour_of_day,
              'created_at',
              time_zone: Time.zone,
              last: nil,
              range: nil,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count).and_return(double(keys: [1, 2, 3]))
          subject
        end
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to(
            receive(:select).with('MOCK_GROUPDATE_GROUP_CLAUSE AS mock_groupdate_group_clause').and_return(models)
          )
          expect(models).to receive(:where).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :hour_of_day,
              'created_at',
              time_zone: Time.zone,
              last: nil,
              range: nil,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:order).with({ 'mock_groupdate_group_clause' => :desc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models.connection).to receive(:select_values).with(models)
          subject
        end

        context 'with subgroup period' do
          let(:subgroup_period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

          it do
            expect(models).to(
              receive(:select).with('MOCK_GROUPDATE_GROUP_CLAUSE AS mock_groupdate_group_clause').and_return(models)
            )
            expect(models).to receive(:where).and_return(models)
            expect(models).to(
              receive(:group_by_period).with(
                :hour_of_day,
                'created_at',
                time_zone: Time.zone,
                last: nil,
                range: nil,
                series: false
              ).and_return(models)
            )
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models.connection).to receive(:select_values).with(models)
            subject
          end
        end
      end
    end

    context 'with a datetime attribute by day of week' do
      let(:subgroup_by_attribute) { 'created_at_day_of_week' }
      let(:expected_groupdate_options) do
        { period: :day_of_week, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
      end

      it do
        expect(models).to receive(:where).and_return(models)
        expect(models).to(
          receive(:group_by_period).with(
            :day_of_week,
            'created_at',
            time_zone: Time.zone,
            last: nil,
            range: nil,
            series: false
          ).and_return(models)
        )
        expect(models).to(
          receive(:order).with({ count_id: :desc, 'mock_groupdate_group_clause' => :desc }).and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to receive(:count).and_return(double(keys: [1, 2, 3]))
        subject
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to(
            receive(:select).with('MOCK_GROUPDATE_GROUP_CLAUSE AS mock_groupdate_group_clause').and_return(models)
          )
          expect(models).to receive(:where).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :day_of_week,
              'created_at',
              time_zone: Time.zone,
              last: nil,
              range: nil,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models.connection).to receive(:select_values).with(models)
          subject
        end
      end
    end

    context 'with a date attribute' do
      let(:subgroup_by_attribute) { 'date' }
      let(:expected_groupdate_options) do
        { period: :day, time_zone: have_attributes(name: 'Etc/UTC'), time_range: nil }
      end

      it do
        keys = [2.days.ago, 1.day.ago, Time.zone.now].map(&:to_date)
        expect(models).to receive(:where).and_return(models)
        expect(models).to(
          receive(:group_by_period).with(
            :day,
            'date',
            time_zone: false,
            last: nil,
            range: nil,
            series: false
          ).and_return(models)
        )
        expect(models).to(
          receive(:order).with({ count_id: :desc, 'mock_groupdate_group_clause' => :desc }).and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to receive(:count).and_return(double(keys: keys))
        subject
      end

      context 'with subgroup period' do
        let(:subgroup_period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }
        let(:expected_groupdate_options) do
          { period: :day, time_zone: have_attributes(name: 'Etc/UTC'), time_range: be_present }
        end

        it do
          keys = [2.days.ago, 1.day.ago, Time.zone.now].map(&:to_date)
          expect(models).to receive(:where).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :day,
              'date',
              time_zone: false,
              last: nil,
              range: be_present,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count).and_return(double(keys: keys))
          subject
        end
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to(
            receive(:select).with('MOCK_GROUPDATE_GROUP_CLAUSE AS mock_groupdate_group_clause').and_return(models)
          )
          expect(models).to receive(:where).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :day,
              'date',
              time_zone: false,
              last: nil,
              range: nil,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:order).with({ 'mock_groupdate_group_clause' => :desc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models.connection).to receive(:select_values).with(models)
          subject
        end

        context 'with subgroup period' do
          let(:subgroup_period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }
          let(:expected_groupdate_options) do
            { period: :day, time_zone: have_attributes(name: 'Etc/UTC'), time_range: be_present }
          end

          it do
            expect(models).to(
              receive(:select).with('MOCK_GROUPDATE_GROUP_CLAUSE AS mock_groupdate_group_clause').and_return(models)
            )
            expect(models).to receive(:where).and_return(models)
            expect(models).to(
              receive(:group_by_period).with(
                :day,
                'date',
                time_zone: false,
                last: nil,
                range: be_present,
                series: false
              ).and_return(models)
            )
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models.connection).to receive(:select_values).with(models)
            subject
          end
        end
      end
    end

    context 'with a date attribute grouped by week' do
      let(:subgroup_by_attribute) { 'date_by_week' }
      let(:expected_groupdate_options) do
        { period: :week, time_zone: have_attributes(name: 'Etc/UTC'), time_range: nil }
      end

      it do
        keys = [2.weeks.ago, 1.week.ago, Time.zone.now].map(&:beginning_of_week).map(&:to_date)
        expect(models).to receive(:where).and_return(models)
        expect(models).to(
          receive(:group_by_period).with(
            :week,
            'date',
            time_zone: false,
            last: nil,
            range: nil,
            series: false
          ).and_return(models)
        )
        expect(models).to(
          receive(:order).with({ count_id: :desc, 'mock_groupdate_group_clause' => :desc }).and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to receive(:count).and_return(double(keys: keys))
        subject
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to(
            receive(:select).with('MOCK_GROUPDATE_GROUP_CLAUSE AS mock_groupdate_group_clause').and_return(models)
          )
          expect(models).to receive(:where).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :week,
              'date',
              time_zone: false,
              last: nil,
              range: nil,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:order).with({ 'mock_groupdate_group_clause' => :desc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models.connection).to receive(:select_values).with(models)
          subject
        end
      end
    end

    context 'with a date attribute grouped by month' do
      let(:subgroup_by_attribute) { 'date_by_month' }
      let(:expected_groupdate_options) do
        { period: :month, time_zone: have_attributes(name: 'Etc/UTC'), time_range: nil }
      end

      it do
        keys = [2.months.ago, 1.month.ago, Time.zone.now].map(&:beginning_of_month).map(&:to_date)
        expect(models).to receive(:where).and_return(models)
        expect(models).to(
          receive(:group_by_period).with(
            :month,
            'date',
            time_zone: false,
            last: nil,
            range: nil,
            series: false
          ).and_return(models)
        )
        expect(models).to(
          receive(:order).with({ count_id: :desc, 'mock_groupdate_group_clause' => :desc }).and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to receive(:count).and_return(double(keys: keys))
        subject
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to(
            receive(:select).with('MOCK_GROUPDATE_GROUP_CLAUSE AS mock_groupdate_group_clause').and_return(models)
          )
          expect(models).to receive(:where).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :month,
              'date',
              time_zone: false,
              last: nil,
              range: nil,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:order).with({ 'mock_groupdate_group_clause' => :desc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models.connection).to receive(:select_values).with(models)
          subject
        end
      end
    end

    context 'with a date attribute by day of week' do
      let(:subgroup_by_attribute) { 'date_day_of_week' }
      let(:expected_groupdate_options) do
        { period: :day_of_week, time_zone: have_attributes(name: 'Etc/UTC'), time_range: nil }
      end

      it do
        expect(models).to receive(:where).and_return(models)
        expect(models).to(
          receive(:group_by_period).with(
            :day_of_week,
            'date',
            time_zone: false,
            last: nil,
            range: nil,
            series: false
          ).and_return(models)
        )
        expect(models).to(
          receive(:order).with({ count_id: :desc, 'mock_groupdate_group_clause' => :desc }).and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to receive(:count).and_return(double(keys: [1, 2, 3]))
        subject
      end

      context 'with subgroup period' do
        let(:subgroup_period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

        it do
          expect(models).to receive(:where).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :day_of_week,
              'date',
              time_zone: false,
              last: nil,
              range: nil,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count).and_return(double(keys: [1, 2, 3]))
          subject
        end
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to(
            receive(:select).with('MOCK_GROUPDATE_GROUP_CLAUSE AS mock_groupdate_group_clause').and_return(models)
          )
          expect(models).to receive(:where).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :day_of_week,
              'date',
              time_zone: false,
              last: nil,
              range: nil,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:order).with({ 'mock_groupdate_group_clause' => :desc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models.connection).to receive(:select_values).with(models)
          subject
        end

        context 'with subgroup period' do
          let(:subgroup_period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

          it do
            expect(models).to(
              receive(:select).with('MOCK_GROUPDATE_GROUP_CLAUSE AS mock_groupdate_group_clause').and_return(models)
            )
            expect(models).to receive(:where).and_return(models)
            expect(models).to(
              receive(:group_by_period).with(
                :day_of_week,
                'date',
                time_zone: false,
                last: nil,
                range: nil,
                series: false
              ).and_return(models)
            )
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models.connection).to receive(:select_values).with(models)
            subject
          end
        end
      end
    end

    context 'with an attribute needing inclusions and select' do
      let(:group_by_attribute) { 'custom_label_attribute' }
      let(:subgroup_by_attribute) { 'custom_label_attribute_b' }
      let(:xaxis) { [['XA1', 'XA2'], ['XB1', 'XB2'], ['XC1', nil]] }

      it do # rubocop:disable Metrics/BlockLength
        expect(models).to(
          receive(:left_outer_joins).with({ relation_b: { other_relation_b: {} }, another_relation_b: {} })
                                    .and_return(models)
        )
        expect(models).to(
          receive(:select).with('other_relation_bs.name', 'another_relation_bs.label').and_return(models)
        )
        expect(models).to(
          receive(:left_outer_joins).with({ relation: { other_relation: {} }, another_relation: {} })
                                    .and_return(models)
        )
        expect(models).to(
          receive(:where).with(
            [
              "(other_relations.name = 'XA1' AND another_relations.label = 'XA2')",
              "(other_relations.name = 'XB1' AND another_relations.label = 'XB2')",
              "(other_relations.name = 'XC1' AND another_relations.label IS NULL)"
            ].join(' OR ')
          ).and_return(models)
        )
        expect(models).to receive(:group).with('other_relation_bs.name', 'another_relation_bs.label').and_return(models)
        expect(models).to(
          receive(:order).with(
                            {
                              count_id: :desc,
                             'other_relation_bs_name' => :desc,
                             'another_relation_bs_label' => :desc
                            }
                          )
                         .and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to(
          receive(:count).with(:id).and_return(double(keys: [['SA1', 'SA2'], ['SB1', 'SB2'], ['SC1', 'SC2']]))
        )
        subject
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do # rubocop:disable Metrics/BlockLength
          expect(models).to(
            receive(:left_outer_joins).with({ relation_b: { other_relation_b: {} }, another_relation_b: {} })
                                      .and_return(models)
          )
          expect(models).to(
            receive(:select).with(
              'other_relation_bs.name AS other_relation_bs_name',
              'another_relation_bs.label AS another_relation_bs_label'
            ).and_return(models)
          )
          expect(models).to(
            receive(:left_outer_joins).with({ relation: { other_relation: {} }, another_relation: {} })
                                      .and_return(models)
          )
          expect(models).to(
            receive(:where).with(
              [
                "(other_relations.name = 'XA1' AND another_relations.label = 'XA2')",
                "(other_relations.name = 'XB1' AND another_relations.label = 'XB2')",
                "(other_relations.name = 'XC1' AND another_relations.label IS NULL)"
              ].join(' OR ')
            ).and_return(models)
          )
          expect(models).to(
            receive(:group).with('other_relation_bs.name', 'another_relation_bs.label').and_return(models)
          )
          expect(models).to(
            receive(:order).with({ 'other_relation_bs_name' => :desc, 'another_relation_bs_label' => :desc })
                           .and_return(models)
          )
          expect(models).to receive(:limit).and_return(models)
          expect(models.connection).to receive(:select_rows).with(models)
          subject
        end

        context 'when #subgroup_first is true' do
          let(:subgroup_first) { true }

          it do
            expect(models).to receive(:left_outer_joins).twice.and_return(models)
            expect(models).to receive(:select).and_return(models)
            expect(models).to receive(:where).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to(
              receive(:order).with({ 'other_relation_bs_name' => :asc, 'another_relation_bs_label' => :asc })
                             .and_return(models)
            )
            expect(models).to receive(:limit).and_return(models)
            expect(models.connection).to receive(:select_rows).with(models)
            subject
          end
        end
      end
    end
  end

  describe '#raw_data' do
    subject { chart.raw_data }

    let(:xaxis) { nil }
    let(:series) { nil }

    before do
      if xaxis
        expect(chart).to receive(:xaxis).at_least(1).and_return(xaxis)
      else
        expect(chart).not_to receive(:xaxis)
      end
      if series
        expect(chart).to receive(:series).at_least(1).and_return(series)
      else
        expect(chart).not_to receive(:series)
      end
    end

    context 'with a simple string attribute' do
      it do
        expect(models).to receive(:group).with('some_attribute').and_return(models)
        expect(models).to receive(:order).with({ count_id: :desc, 'some_attribute' => :desc }).and_return(models)
        expect(models).to receive(:limit).with(10).and_return(models)
        expect(models).to receive(:count).with(:id)
        subject
      end

      context 'when #first is true' do
        let(:first) { true }

        it do
          expect(models).to receive(:group).and_return(models)
          expect(models).to receive(:order).with({ count_id: :asc, 'some_attribute' => :asc }).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count)
          subject
        end
      end

      context 'when #top_count is 100' do
        let(:top_count) { 100 }

        it do
          expect(models).to receive(:group).and_return(models)
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).with(100).and_return(models)
          expect(models).to receive(:count)
          subject
        end
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to receive(:group).with('some_attribute').and_return(models)
          expect(models).to receive(:order).with({ 'some_attribute' => :desc }).and_return(models)
          expect(models).to receive(:limit).with(10).and_return(models)
          expect(models).to receive(:count).with(:id)
          subject
        end

        context 'when #first is true' do
          let(:first) { true }

          it do
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).with({ 'some_attribute' => :asc }).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count)
            subject
          end
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_other_attribute' }
        let(:subgroup_by_attribute) { 'some_attribute' }
        let(:xaxis) { ['X', 'Y', nil] }
        let(:series) { ['A', 'B', nil] }

        it do # rubocop:disable Metrics/BlockLength
          expect(models).to(
            receive(:where).with(
              [
                "(some_other_attribute = 'X')",
                "(some_other_attribute = 'Y')",
                '(some_other_attribute IS NULL)'
              ].join(' OR ')
            ).and_return(models)
          )
          expect(models).to(
            receive(:where).with(
              [
                "(some_attribute = 'A')",
                "(some_attribute = 'B')",
                '(some_attribute IS NULL)'
              ].join(' OR ')
            ).and_return(models)
          )
          expect(models).to receive(:group).with('some_attribute').and_return(models)
          expect(models).to receive(:group).with('some_other_attribute').and_return(models)
          expect(models).to(
            receive(:order).with({ count_id: :desc, 'some_other_attribute' => :desc, 'some_attribute' => :desc })
                           .and_return(models)
          )
          expect(models).to receive(:limit).with(50).and_return(models)
          expect(models).to receive(:count).with(:id)
          subject
        end

        context 'when #first is true' do
          let(:first) { true }

          it do
            expect(models).to receive(:where).twice.and_return(models)
            expect(models).to receive(:group).twice.and_return(models)
            expect(models).to(
              receive(:order).with({ count_id: :asc, 'some_other_attribute' => :asc, 'some_attribute' => :desc })
                             .and_return(models)
            )
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count)
            subject
          end
        end

        context 'when #subgroup_first is true' do
          let(:subgroup_first) { true }

          it do
            expect(models).to receive(:where).twice.and_return(models)
            expect(models).to receive(:group).twice.and_return(models)
            expect(models).to(
              receive(:order).with({ count_id: :desc, 'some_other_attribute' => :desc, 'some_attribute' => :asc })
                             .and_return(models)
            )
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count)
            subject
          end
        end

        context 'when #sort_by is "label"' do
          let(:sort_by) { 'label' }

          it do
            expect(models).to receive(:where).twice.and_return(models)
            expect(models).to receive(:group).twice.and_return(models)
            expect(models).to(
              receive(:order).with({ 'some_other_attribute' => :desc, 'some_attribute' => :desc }).and_return(models)
            )
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count)
            subject
          end

          context 'when #first is true' do
            let(:first) { true }

            it do
              expect(models).to receive(:where).twice.and_return(models)
              expect(models).to receive(:group).twice.and_return(models)
              expect(models).to(
                receive(:order).with({ 'some_other_attribute' => :asc, 'some_attribute' => :desc }).and_return(models)
              )
              expect(models).to receive(:limit).and_return(models)
              expect(models).to receive(:count)
              subject
            end
          end

          context 'when #subgroup_first is true' do
            let(:subgroup_first) { true }

            it do
              expect(models).to receive(:where).twice.and_return(models)
              expect(models).to receive(:group).twice.and_return(models)
              expect(models).to(
                receive(:order).with({ 'some_other_attribute' => :desc, 'some_attribute' => :asc }).and_return(models)
              )
              expect(models).to receive(:limit).and_return(models)
              expect(models).to receive(:count)
              subject
            end
          end
        end
      end
    end

    context 'with a numeric attribute' do
      let(:group_by_attribute) { 'some_numeric_attribute' }

      context 'with #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'some_attribute' }
        let(:series) { ['A', 'B', nil] }

        it do
          expect(models).to(
            receive(:where).with(
              [
                "(some_attribute = 'A')",
                "(some_attribute = 'B')",
                '(some_attribute IS NULL)'
              ].join(' OR ')
            ).and_return(models)
          )
          expect(models).to receive(:group).twice.and_return(models)
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count)
          subject
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'some_numeric_attribute' }
        let(:xaxis) { ['A', 'B', nil] }
        let(:series) { [1, 2, nil] }

        it do
          expect(models).to(
            receive(:where).with(
              [
                '(some_numeric_attribute = 1)',
                '(some_numeric_attribute = 2)',
                '(some_numeric_attribute IS NULL)'
              ].join(' OR ')
            ).and_return(models)
          )
          expect(models).to(
            receive(:where).with(
              [
                "(some_attribute = 'A')",
                "(some_attribute = 'B')",
                '(some_attribute IS NULL)'
              ].join(' OR ')
            ).and_return(models)
          )
          expect(models).to receive(:group).twice.and_return(models)
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count)
          subject
        end
      end

      context 'with keys' do
        let(:group_by_attribute) { 'more_keys_attribute' }

        context 'with #subgroup_by_attribute' do
          let(:subgroup_by_attribute) { 'some_attribute' }
          let(:xaxis) { [1, 2, nil] }
          let(:series) { ['A', 'B', nil] }

          it do
            expect(models).to(
              receive(:where).with(
                [
                  "(some_attribute = 'A')",
                  "(some_attribute = 'B')",
                  '(some_attribute IS NULL)'
                ].join(' OR ')
              ).and_return(models)
            )
            expect(models).to(
              receive(:where).with(
                [
                  '(more_keys_attribute = 1)',
                  '(more_keys_attribute = 2)',
                  '(more_keys_attribute IS NULL)'
                ].join(' OR ')
              ).and_return(models)
            )
            expect(models).to receive(:group).twice.and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count)
            subject
          end
        end

        context 'as #subgroup_by_attribute' do
          let(:group_by_attribute) { 'some_attribute' }
          let(:subgroup_by_attribute) { 'more_keys_attribute' }
          let(:xaxis) { ['A', 'B', nil] }
          let(:series) { [1, 2, nil] }

          it do
            expect(models).to(
              receive(:where).with(
                [
                  '(more_keys_attribute = 1)',
                  '(more_keys_attribute = 2)',
                  '(more_keys_attribute IS NULL)'
                ].join(' OR ')
              ).and_return(models)
            )
            expect(models).to(
              receive(:where).with(
                [
                  "(some_attribute = 'A')",
                  "(some_attribute = 'B')",
                  '(some_attribute IS NULL)'
                ].join(' OR ')
              ).and_return(models)
            )
            expect(models).to receive(:group).twice.and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).with(50).and_return(models)
            expect(models).to receive(:count).with(:id)
            subject
          end
        end
      end
    end

    context 'with a datetime attribute' do
      let(:group_by_attribute) { 'created_at' }

      it do
        expect(models).to(
          receive(:group_by_period).with(:day, 'created_at', last: 10, range: nil, time_zone: Time.zone)
                                   .and_return(models)
        )
        expect(models).to receive(:count)
        subject
      end

      context 'when #first is true' do
        let(:first) { true }

        it do
          expect(models).to(
            receive(:group_by_period).with(:day, 'created_at', last: 10, range: nil, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'when #top_count is 100' do
        let(:top_count) { 100 }

        it do
          expect(models).to(
            receive(:group_by_period).with(:day, 'created_at', last: 100, range: nil, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'with period' do
        let(:period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

        it do
          expect(models).to(
            receive(:group_by_period).with(:day, 'created_at', last: 10, range: period, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'with #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'some_attribute' }
        let(:series) { ['A', 'B', nil] }

        it do
          expect(models).to(
            receive(:where).with(
              [
                "(some_attribute = 'A')",
                "(some_attribute = 'B')",
                '(some_attribute IS NULL)'
              ].join(' OR ')
            ).and_return(models)
          )
          expect(models).to receive(:group).with('some_attribute').and_return(models)
          expect(models).to(
            receive(:group_by_period).with(:day, 'created_at', last: 50, range: nil, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end

        context 'with period' do
          let(:period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

          it do
            expect(models).to receive(:where).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to(
              receive(:group_by_period).with(:day, 'created_at', last: 50, range: period, time_zone: Time.zone)
                                       .and_return(models)
            )
            expect(models).to receive(:count)
            subject
          end
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'created_at' }
        let(:expected_groupdate_options) do
          { period: :day, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
        end
        let(:xaxis) { ['A', 'B', nil] }
        let(:series) { [2.days.ago, 1.day.ago, Time.zone.now].map(&:to_date) }

        it do # rubocop:disable Metrics/BlockLength
          expect(models).to(
            receive(:where).with(
              [
                "(MOCK_GROUPDATE_GROUP_CLAUSE = #{ActiveRecord::Base.connection.quote(2.days.ago.to_date)})",
                "(MOCK_GROUPDATE_GROUP_CLAUSE = #{ActiveRecord::Base.connection.quote(1.day.ago.to_date)})",
                "(MOCK_GROUPDATE_GROUP_CLAUSE = #{ActiveRecord::Base.connection.quote(Time.zone.now.to_date)})"
              ].join(' OR ')
            ).and_return(models)
          )
          expect(models).to(
            receive(:where).with(
              [
                "(some_attribute = 'A')",
                "(some_attribute = 'B')",
                '(some_attribute IS NULL)'
              ].join(' OR ')
            ).and_return(models)
          )
          expect(models).to(
            receive(:group_by_period).with(
              :day,
              'created_at',
              last: nil,
              range: nil,
              time_zone: Time.zone,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:group).with('some_attribute').and_return(models)
          expect(models).to(
            receive(:order).with({ count_id: :desc, 'some_attribute' => :desc, 'mock_groupdate_group_clause' => :desc })
                           .and_return(models)
          )
          expect(models).to receive(:limit).with(50).and_return(models)
          expect(models).to receive(:count)
          subject
        end

        context 'with subgroup period' do
          let(:subgroup_period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }
          let(:expected_groupdate_options) do
            { period: :day, time_zone: have_attributes(name: Time.zone.name), time_range: be_present }
          end

          it do
            expect(models).to receive(:where).twice.and_return(models)
            expect(models).to(
              receive(:group_by_period).with(
                :day,
                'created_at',
                last: nil,
                range: subgroup_period,
                time_zone: Time.zone,
                series: false
              ).and_return(models)
            )
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count)
            subject
          end
        end
      end
    end

    context 'with a datetime attribute grouped by week' do
      let(:group_by_attribute) { 'created_at_by_week' }

      it do
        expect(models).to(
          receive(:group_by_period).with(:week, 'created_at', last: 10, range: nil, time_zone: Time.zone)
                                   .and_return(models)
        )
        expect(models).to receive(:count)
        subject
      end

      context 'when #first is true' do
        let(:first) { true }

        it do
          expect(models).to(
            receive(:group_by_period).with(:week, 'created_at', last: 10, range: nil, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'when #top_count is 100' do
        let(:top_count) { 100 }

        it do
          expect(models).to(
            receive(:group_by_period).with(:week, 'created_at', last: 100, range: nil, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'with period' do
        let(:period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

        it do
          expect(models).to(
            receive(:group_by_period).with(:week, 'created_at', last: 10, range: period, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'with #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'some_attribute' }
        let(:series) { ['A', 'B', nil] }

        it do
          expect(models).to receive(:where).and_return(models)
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(:week, 'created_at', last: 50, range: nil, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'created_at_by_week' }
        let(:expected_groupdate_options) do
          { period: :week, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
        end
        let(:xaxis) { ['A', 'B', nil] }
        let(:series) { [2.weeks.ago, 1.week.ago, Time.zone.now].map(&:beginning_of_week).map(&:to_date) }

        it do
          expect(models).to receive(:where).twice.and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :week,
              'created_at',
              last: nil,
              range: nil,
              time_zone: Time.zone,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:group).and_return(models)
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count)
          subject
        end
      end
    end

    context 'with a datetime attribute grouped by month' do
      let(:group_by_attribute) { 'created_at_by_month' }

      it do
        expect(models).to(
          receive(:group_by_period).with(:month, 'created_at', last: 10, range: nil, time_zone: Time.zone)
                                   .and_return(models)
        )
        expect(models).to receive(:count)
        subject
      end

      context 'when #first is true' do
        let(:first) { true }

        it do
          expect(models).to(
            receive(:group_by_period).with(:month, 'created_at', last: 10, range: nil, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'when #top_count is 100' do
        let(:top_count) { 100 }

        it do
          expect(models).to(
            receive(:group_by_period).with(:month, 'created_at', last: 100, range: nil, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'with period' do
        let(:period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

        it do
          expect(models).to(
            receive(:group_by_period).with(:month, 'created_at', last: 10, range: period, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'with #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'some_attribute' }
        let(:series) { ['A', 'B', nil] }

        it do
          expect(models).to receive(:where).and_return(models)
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(:month, 'created_at', last: 50, range: nil, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'created_at_by_month' }
        let(:expected_groupdate_options) do
          { period: :month, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
        end
        let(:xaxis) { ['A', 'B', nil] }
        let(:series) { [2.months.ago, 1.month.ago, Time.zone.now].map(&:beginning_of_month).map(&:to_date) }

        it do
          expect(models).to receive(:where).twice.and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :month,
              'created_at',
              last: nil,
              range: nil,
              time_zone: Time.zone,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:group).and_return(models)
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count)
          subject
        end
      end
    end

    context 'with a datetime attribute by hour of day' do
      let(:group_by_attribute) { 'created_at_hour_of_day' }

      it do
        expect(models).to(
          receive(:group_by_period).with(:hour_of_day, 'created_at', last: nil, range: nil, time_zone: Time.zone)
                                   .and_return(models)
        )
        expect(models).to receive(:count)
        subject
      end

      context 'with #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'some_attribute' }
        let(:series) { ['A', 'B', nil] }

        it do
          expect(models).to receive(:where).and_return(models)
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(:hour_of_day, 'created_at', last: nil, range: nil, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end

        context 'with period' do
          let(:period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

          it do
            expect(models).to receive(:where).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to(
              receive(:group_by_period).with(:hour_of_day, 'created_at', last: nil, range: nil, time_zone: Time.zone)
                                       .and_return(models)
            )
            expect(models).to receive(:count)
            subject
          end
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'created_at_hour_of_day' }
        let(:expected_groupdate_options) do
          { period: :hour_of_day, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
        end
        let(:xaxis) { ['A', 'B', nil] }
        let(:series) { [1, 2, 3] }

        it do
          expect(models).to receive(:where).twice.and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :hour_of_day,
              'created_at',
              last: nil,
              range: nil,
              time_zone: Time.zone,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:group).and_return(models)
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count)
          subject
        end

        context 'with subgroup period' do
          let(:subgroup_period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

          it do
            expect(models).to receive(:where).twice.and_return(models)
            expect(models).to(
              receive(:group_by_period).with(
                :hour_of_day,
                'created_at',
                last: nil,
                range: nil,
                time_zone: Time.zone,
                series: false
              ).and_return(models)
            )
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count)
            subject
          end
        end
      end
    end

    context 'with a datetime attribute by day of week' do
      let(:group_by_attribute) { 'created_at_day_of_week' }

      it do
        expect(models).to(
          receive(:group_by_period).with(:day_of_week, 'created_at', last: nil, range: nil, time_zone: Time.zone)
                                   .and_return(models)
        )
        expect(models).to receive(:count)
        subject
      end

      context 'with #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'some_attribute' }
        let(:series) { ['A', 'B', nil] }

        it do
          expect(models).to receive(:where).and_return(models)
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(:day_of_week, 'created_at', last: nil, range: nil, time_zone: Time.zone)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'created_at_day_of_week' }
        let(:expected_groupdate_options) do
          { period: :day_of_week, time_zone: have_attributes(name: Time.zone.name), time_range: nil }
        end
        let(:xaxis) { ['A', 'B', nil] }
        let(:series) { [1, 2, 3] }

        it do
          expect(models).to receive(:where).twice.and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :day_of_week,
              'created_at',
              last: nil,
              range: nil,
              time_zone: Time.zone,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:order).with({ count_id: :desc, 'some_attribute' => :desc, 'mock_groupdate_group_clause' => :desc })
                           .and_return(models)
          )
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count)
          subject
        end
      end
    end

    context 'with a date attribute' do
      let(:group_by_attribute) { 'date' }

      it do
        expect(models).to(
          receive(:group_by_period).with(:day, 'date', last: 10, range: nil, time_zone: false).and_return(models)
        )
        expect(models).to receive(:count)
        subject
      end

      context 'with #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'some_attribute' }
        let(:series) { ['A', 'B', nil] }

        it do
          expect(models).to(
            receive(:where).with(
              [
                "(some_attribute = 'A')",
                "(some_attribute = 'B')",
                '(some_attribute IS NULL)'
              ].join(' OR ')
            ).and_return(models)
          )
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(:day, 'date', last: 50, range: nil, time_zone: false)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end

        context 'with period' do
          let(:period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

          it do
            expect(models).to receive(:where).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to(
              receive(:group_by_period).with(:day, 'date', last: 50, range: period, time_zone: false)
                                       .and_return(models)
            )
            expect(models).to receive(:count)
            subject
          end
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'date' }
        let(:expected_groupdate_options) do
          { period: :day, time_zone: have_attributes(name: 'Etc/UTC'), time_range: nil }
        end
        let(:xaxis) { ['A', 'B', nil] }
        let(:series) { [2.days.ago, 1.day.ago, Time.zone.now].map(&:to_date) }

        it do # rubocop:disable Metrics/BlockLength
          expect(models).to(
            receive(:where).with(
              [
                "(MOCK_GROUPDATE_GROUP_CLAUSE = #{ActiveRecord::Base.connection.quote(2.days.ago.to_date)})",
                "(MOCK_GROUPDATE_GROUP_CLAUSE = #{ActiveRecord::Base.connection.quote(1.day.ago.to_date)})",
                "(MOCK_GROUPDATE_GROUP_CLAUSE = #{ActiveRecord::Base.connection.quote(Time.zone.now.to_date)})"
              ].join(' OR ')
            ).and_return(models)
          )
          expect(models).to(
            receive(:where).with(
              [
                "(some_attribute = 'A')",
                "(some_attribute = 'B')",
                '(some_attribute IS NULL)'
              ].join(' OR ')
            ).and_return(models)
          )
          expect(models).to(
            receive(:group_by_period).with(
              :day,
              'date',
              last: nil,
              range: nil,
              time_zone: false,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:group).with('some_attribute').and_return(models)
          expect(models).to(
            receive(:order).with({ count_id: :desc, 'some_attribute' => :desc, 'mock_groupdate_group_clause' => :desc })
                           .and_return(models)
          )
          expect(models).to receive(:limit).with(50).and_return(models)
          expect(models).to receive(:count)
          subject
        end

        context 'with subgroup period' do
          let(:subgroup_period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }
          let(:expected_groupdate_options) do
            { period: :day, time_zone: have_attributes(name: 'Etc/UTC'), time_range: be_present }
          end

          it do
            expect(models).to receive(:where).twice.and_return(models)
            expect(models).to(
              receive(:group_by_period).with(
                :day,
                'date',
                last: nil,
                range: subgroup_period,
                time_zone: false,
                series: false
              ).and_return(models)
            )
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count)
            subject
          end
        end
      end
    end

    context 'with a date attribute grouped by week' do
      let(:group_by_attribute) { 'date_by_week' }

      it do
        expect(models).to(
          receive(:group_by_period).with(:week, 'date', last: 10, range: nil, time_zone: false).and_return(models)
        )
        expect(models).to receive(:count)
        subject
      end

      context 'with #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'some_attribute' }
        let(:series) { ['A', 'B', nil] }

        it do
          expect(models).to receive(:where).and_return(models)
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(:week, 'date', last: 50, range: nil, time_zone: false)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'date_by_week' }
        let(:expected_groupdate_options) do
          { period: :week, time_zone: have_attributes(name: 'Etc/UTC'), time_range: nil }
        end
        let(:xaxis) { ['A', 'B', nil] }
        let(:series) { [2.weeks.ago, 1.week.ago, Time.zone.now].map(&:beginning_of_week).map(&:to_date) }

        it do
          expect(models).to receive(:where).twice.and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :week,
              'date',
              last: nil,
              range: nil,
              time_zone: false,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:group).and_return(models)
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count)
          subject
        end
      end
    end

    context 'with a date attribute grouped by month' do
      let(:group_by_attribute) { 'date_by_month' }

      it do
        expect(models).to(
          receive(:group_by_period).with(:month, 'date', last: 10, range: nil, time_zone: false).and_return(models)
        )
        expect(models).to receive(:count)
        subject
      end

      context 'with #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'some_attribute' }
        let(:series) { ['A', 'B', nil] }

        it do
          expect(models).to receive(:where).and_return(models)
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(:month, 'date', last: 50, range: nil, time_zone: false)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'date_by_month' }
        let(:expected_groupdate_options) do
          { period: :month, time_zone: have_attributes(name: 'Etc/UTC'), time_range: nil }
        end
        let(:xaxis) { ['A', 'B', nil] }
        let(:series) { [2.months.ago, 1.month.ago, Time.zone.now].map(&:beginning_of_month).map(&:to_date) }

        it do
          expect(models).to receive(:where).twice.and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :month,
              'date',
              last: nil,
              range: nil,
              time_zone: false,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:group).and_return(models)
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).with(50).and_return(models)
          expect(models).to receive(:count).with(:id)
          subject
        end
      end
    end

    context 'with a date attribute by day of week' do
      let(:group_by_attribute) { 'date_day_of_week' }

      it do
        expect(models).to(
          receive(:group_by_period).with(:day_of_week, 'date', last: nil, range: nil, time_zone: false)
                                   .and_return(models)
        )
        expect(models).to receive(:count)
        subject
      end

      context 'with #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'some_attribute' }
        let(:series) { ['A', 'B', nil] }

        it do
          expect(models).to receive(:where).and_return(models)
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:group_by_period).with(:day_of_week, 'date', last: nil, range: nil, time_zone: false)
                                     .and_return(models)
          )
          expect(models).to receive(:count)
          subject
        end

        context 'with period' do
          let(:period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

          it do
            expect(models).to receive(:where).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to(
              receive(:group_by_period).with(:day_of_week, 'date', last: nil, range: nil, time_zone: false)
                                       .and_return(models)
            )
            expect(models).to receive(:count)
            subject
          end
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'date_day_of_week' }
        let(:expected_groupdate_options) do
          { period: :day_of_week, time_zone: have_attributes(name: 'Etc/UTC'), time_range: nil }
        end
        let(:xaxis) { ['A', 'B', nil] }
        let(:series) { [1, 2, 3] }

        it do
          expect(models).to receive(:where).twice.and_return(models)
          expect(models).to(
            receive(:group_by_period).with(
              :day_of_week,
              'date',
              last: nil,
              range: nil,
              time_zone: false,
              series: false
            ).and_return(models)
          )
          expect(models).to receive(:group).and_return(models)
          expect(models).to receive(:order).and_return(models)
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count)
          subject
        end

        context 'with subgroup period' do
          let(:subgroup_period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

          it do
            expect(models).to receive(:where).twice.and_return(models)
            expect(models).to(
              receive(:group_by_period).with(
                :day_of_week,
                'date',
                last: nil,
                range: nil,
                time_zone: false,
                series: false
              ).and_return(models)
            )
            expect(models).to receive(:group).and_return(models)
            expect(models).to receive(:order).and_return(models)
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count)
            subject
          end
        end
      end
    end

    context 'with an attribute having a complex select' do
      let(:group_by_attribute) { 'complex_select_attribute' }

      it do
        expect(models).to(
          receive(:select).with('CASE WHEN 1 "true" ELSE "false" END').and_return(models)
        )
        expect(models).to(
          receive(:group).with('CASE WHEN 1 "true" ELSE "false" END').and_return(models)
        )
        expect(models).to(
          receive(:order).with({ count_id: :desc, 'case_when_1_true_else_false_end' => :desc }).and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to receive(:count)
        subject
      end
    end

    context 'with an attribute needing inclusions and select' do
      let(:group_by_attribute) { 'custom_label_attribute' }

      it do
        expect(models).to(
          receive(:left_outer_joins).with({ relation: { other_relation: {} }, another_relation: {} })
                                    .and_return(models)
        )
        expect(models).to(
          receive(:select).with('other_relations.name', 'another_relations.label').and_return(models)
        )
        expect(models).to(
          receive(:group).with('other_relations.name', 'another_relations.label').and_return(models)
        )
        expect(models).to(
          receive(:order).with({ count_id: :desc, 'other_relations_name' => :desc, 'another_relations_label' => :desc })
                         .and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to receive(:count)
        subject
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it do
          expect(models).to receive(:left_outer_joins).and_return(models)
          expect(models).to receive(:select).and_return(models)
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:order).with({ 'other_relations_name' => :desc, 'another_relations_label' => :desc })
                           .and_return(models)
          )
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:count)
          subject
        end

        context 'when #first is true' do
          let(:first) { true }

          it do
            expect(models).to receive(:left_outer_joins).and_return(models)
            expect(models).to receive(:select).and_return(models)
            expect(models).to receive(:group).and_return(models)
            expect(models).to(
              receive(:order).with({ 'other_relations_name' => :asc, 'another_relations_label' => :asc })
                             .and_return(models)
            )
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count)
            subject
          end
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'custom_label_attribute_b' }

        let(:xaxis) { [['XA1', 'XA2'], ['XB1', 'XB2'], ['XC1', nil]] }
        let(:series) { [['SA1', 'SA2'], ['SB1', 'SB2'], ['SC1', nil]] }

        it do # rubocop:disable Metrics/BlockLength
          expect(models).to(
            receive(:left_outer_joins).with({ relation_b: { other_relation_b: {} }, another_relation_b: {} })
                                      .and_return(models)
          )
          expect(models).to(
            receive(:select).with('other_relation_bs.name', 'another_relation_bs.label').and_return(models)
          )
          expect(models).to(
            receive(:left_outer_joins).with({ relation: { other_relation: {} }, another_relation: {} })
                                      .and_return(models)
          )
          expect(models).to(
            receive(:select).with('other_relations.name', 'another_relations.label').and_return(models)
          )
          expect(models).to receive(:where).with(
            [
              "(other_relation_bs.name = 'SA1' AND another_relation_bs.label = 'SA2')",
              "(other_relation_bs.name = 'SB1' AND another_relation_bs.label = 'SB2')",
              "(other_relation_bs.name = 'SC1' AND another_relation_bs.label IS NULL)"
            ].join(' OR ')
          ).and_return(models)
          expect(models).to receive(:where).with(
            [
              "(other_relations.name = 'XA1' AND another_relations.label = 'XA2')",
              "(other_relations.name = 'XB1' AND another_relations.label = 'XB2')",
              "(other_relations.name = 'XC1' AND another_relations.label IS NULL)"
            ].join(' OR ')
          ).and_return(models)
          expect(models).to(
            receive(:group).with('other_relation_bs.name', 'another_relation_bs.label').and_return(models)
          )
          expect(models).to(
            receive(:group).with('other_relations.name', 'another_relations.label').and_return(models)
          )
          expect(models).to(
            receive(:order).with(
              {
                count_id: :desc,
                'other_relations_name' => :desc,
                'another_relations_label' => :desc,
                'other_relation_bs_name' => :desc,
                'another_relation_bs_label' => :desc
              }
            ).and_return(models)
          )
          expect(models).to receive(:limit).with(50).and_return(models)
          expect(models).to receive(:count)
          subject
        end

        context 'when #subgroup_first is true' do
          let(:subgroup_first) { true }

          it do
            expect(models).to receive(:left_outer_joins).twice.and_return(models)
            expect(models).to receive(:select).twice.and_return(models)
            expect(models).to receive(:where).twice.and_return(models)
            expect(models).to receive(:group).twice.and_return(models)
            expect(models).to(
              receive(:order).with(
                {
                  count_id: :desc,
                  'other_relations_name' => :desc,
                  'another_relations_label' => :desc,
                  'other_relation_bs_name' => :asc,
                  'another_relation_bs_label' => :asc
                }
              ).and_return(models)
            )
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count)
            subject
          end
        end

        context 'when #sort_by is "label"' do
          let(:sort_by) { 'label' }

          it do
            expect(models).to receive(:left_outer_joins).twice.and_return(models)
            expect(models).to receive(:select).twice.and_return(models)
            expect(models).to receive(:where).twice.and_return(models)
            expect(models).to receive(:group).twice.and_return(models)
            expect(models).to(
              receive(:order).with(
                {
                  'other_relations_name' => :desc,
                  'another_relations_label' => :desc,
                  'other_relation_bs_name' => :desc,
                  'another_relation_bs_label' => :desc
                }
              ).and_return(models)
            )
            expect(models).to receive(:limit).and_return(models)
            expect(models).to receive(:count)
            subject
          end

          context 'when #subgroup_first is true' do
            let(:subgroup_first) { true }

            it do
              expect(models).to receive(:left_outer_joins).twice.and_return(models)
              expect(models).to receive(:select).twice.and_return(models)
              expect(models).to receive(:where).twice.and_return(models)
              expect(models).to receive(:group).twice.and_return(models)
              expect(models).to(
                receive(:order).with(
                  {
                    'other_relations_name' => :desc,
                    'another_relations_label' => :desc,
                    'other_relation_bs_name' => :asc,
                    'another_relation_bs_label' => :asc
                  }
                ).and_return(models)
              )
              expect(models).to receive(:limit).and_return(models)
              expect(models).to receive(:count)
              subject
            end
          end
        end
      end
    end

    context 'when #aggregate_operation is "sum"' do
      let(:aggregate_operation) { 'sum' }
      let(:aggregate_attribute) { 'some_numeric_attribute' }

      context 'when #aggregate_attribute is numeric' do
        it do
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:order).with({ 'sum_some_numeric_attribute' => :desc, 'some_attribute' => :desc })
                           .and_return(models)
          )
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:sum).with('some_numeric_attribute')
          subject
        end
      end

      context 'when #aggregate_attribute has a custom definition' do
        let(:aggregate_attribute) { 'custom_aggregate_attribute' }

        it do
          expect(models).to receive(:group).and_return(models)
          expect(models).to(
            receive(:order).with({ 'sum_extract_epoch_from_updated_at_created_at' => :desc, 'some_attribute' => :desc })
                           .and_return(models)
          )
          expect(models).to receive(:limit).and_return(models)
          expect(models).to receive(:sum).with('EXTRACT(EPOCH FROM updated_at - created_at)')
          subject
        end
      end
    end

    context 'when #aggregate_operation is "average"' do
      let(:aggregate_operation) { 'average' }
      let(:aggregate_attribute) { 'some_numeric_attribute' }

      it do
        expect(models).to receive(:group).and_return(models)
        expect(models).to(
          receive(:order).with({ 'average_some_numeric_attribute' => :desc, 'some_attribute' => :desc })
                         .and_return(models)
        )
        expect(models).to receive(:limit).and_return(models)
        expect(models).to receive(:average).with('some_numeric_attribute')
        subject
      end
    end
  end

  describe '#data' do
    subject { chart.data }

    let(:xaxis) { nil }
    let(:raw_data) { {} }

    before do
      if xaxis
        expect(chart).to receive(:xaxis).at_least(1).and_return(xaxis)
      else
        expect(chart).not_to receive(:xaxis)
      end
      expect(chart).to receive(:raw_data).and_return(raw_data)
    end

    context 'with a simple attribute' do
      let(:raw_data) { { 'B' => 3, 'C' => 2, 'A' => 1 } }

      it 'returns data sorted by value' do
        is_expected.to eq_with_keys_order({ 'B' => 3, 'C' => 2, 'A' => 1 })
      end

      context 'when there is nil key' do
        let(:raw_data) { { nil => 4, 'B' => 3, 'C' => 2, 'A' => 1 } }

        it 'replaces nil by "None"' do
          is_expected.to eq_with_keys_order({ I18n.t('none') => 4, 'B' => 3, 'C' => 2, 'A' => 1 })
        end
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }
        let(:raw_data) { { nil => 4, 'C' => 2, 'B' => 3, 'A' => 1 } }

        it 'replaces nil by "None"' do
          is_expected.to eq_with_keys_order({ I18n.t('none') => 4, 'C' => 2, 'B' => 3, 'A' => 1 })
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'some_numeric_attribute' }
        let(:xaxis) { ['C', 'A'] }
        let(:raw_data) { { [2, 'C'] => 4, [1, 'A'] => 3, [1, 'C'] => 2, [2, 'A'] => 1 } }

        it 'returns sorted series, in xaxis order' do
          is_expected.to match(
            [
              { name: 2, data: eq_with_keys_order({ 'C' => 4, 'A' => 1 }) },
              { name: 1, data: eq_with_keys_order({ 'C' => 2, 'A' => 3 }) }
            ]
          )
        end

        context 'with missing keys' do
          let(:raw_data) { { [2, 'C'] => 4, [1, 'A'] => 3, [1, 'C'] => 2 } }

          it 'adds 0 to missing keys' do
            is_expected.to match(
              [
                { name: 2, data: eq_with_keys_order({ 'C' => 4, 'A' => 0 }) },
                { name: 1, data: eq_with_keys_order({ 'C' => 2, 'A' => 3 }) }
              ]
            )
          end
        end

        context 'when there are nil keys' do
          let(:xaxis) { [nil, 'A', 'C'] }
          let(:raw_data) { { [nil, nil] => 6, [2, nil] => 5, [1, 'A'] => 3, [1, 'C'] => 2, [nil, 'A'] => 1 } }

          it 'replaces all nil by "None"' do
            is_expected.to match(
              [
                { name: I18n.t('none'), data: eq_with_keys_order({ I18n.t('none') => 6, 'A' => 1, 'C' => 0 }) },
                { name: 2, data: eq_with_keys_order({ I18n.t('none') => 5, 'A' => 0, 'C' => 0 }) },
                { name: 1, data: eq_with_keys_order({ I18n.t('none') => 0, 'A' => 3, 'C' => 2 }) }
              ]
            )
          end
        end

        context 'when #subgroup_first is true' do
          let(:subgroup_first) { true }

          it 'returns sorted series in reverse, in xaxis order' do
            is_expected.to match(
              [
                { name: 1, data: eq_with_keys_order({ 'C' => 2, 'A' => 3 }) },
                { name: 2, data: eq_with_keys_order({ 'C' => 4, 'A' => 1 }) }
              ]
            )
          end

          context 'when there are nil keys' do
            let(:xaxis) { [nil, 'A', 'C'] }
            let(:raw_data) { { [nil, nil] => 6, [2, nil] => 5, [1, 'A'] => 3, [1, 'C'] => 2, [nil, 'A'] => 1 } }

            it 'replaces all nil by "None", in reverse' do
              is_expected.to match(
                [
                  { name: 1, data: eq_with_keys_order({ I18n.t('none') => 0, 'A' => 3, 'C' => 2 }) },
                  { name: 2, data: eq_with_keys_order({ I18n.t('none') => 5, 'A' => 0, 'C' => 0 }) },
                  { name: I18n.t('none'), data: eq_with_keys_order({ I18n.t('none') => 6, 'A' => 1, 'C' => 0 }) }
                ]
              )
            end
          end
        end

        context 'when a x-axis becomes empty because of subgroup top count' do
          # Consider a chart that normally returns this data:
          # { [2, 'C'] => 5, [1, 'A'] => 4, [1, 'C'] => 3, [2, 'A'] => 2, [3, 'B'] => 1 }
          # Its xaxis is ['C', 'A', 'B'] and its series is [1, 2, 3].
          # If we set subgroup_top_count to 2, the series becomes [1, 2] and the series 3 disappears.
          # Therefore, the x-xaxis tick 'B' has no value. We should remove it
          let(:subgroup_top_count) { 2 }
          let(:xaxis) { ['C', 'A', 'B'] }
          let(:raw_data) { { [2, 'C'] => 5, [1, 'A'] => 4, [1, 'C'] => 3, [2, 'A'] => 2 } }

          it 'returns sorted series, in xaxis order, without adding useless ticks' do
            is_expected.to match(
              [
                { name: 2, data: eq_with_keys_order({ 'C' => 5, 'A' => 2 }) },
                { name: 1, data: eq_with_keys_order({ 'C' => 3, 'A' => 4 }) }
              ]
            )
          end
        end
      end
    end

    context 'with a datetime attribute' do
      let(:group_by_attribute) { 'created_at' }
      let(:raw_data) { { Date.parse('2024-09-01') => 42, Date.parse('2024-09-02') => 21 } }

      it 'returns data' do
        is_expected.to eq({ Date.parse('2024-09-01') => 42, Date.parse('2024-09-02') => 21 })
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'created_at' }
        let(:xaxis) { ['A', 'B'] }
        let(:raw_data) do
          {
            [Date.parse('2024-09-01'), 'A'] => 42,
            [Date.parse('2024-09-02'), 'A'] => 21,
            [Date.parse('2024-09-01'), 'B'] => 12
          }
        end

        it 'labels series name' do
          is_expected.to match(
            [
              { name: I18n.l(Date.parse('2024-09-02')), data: { 'A' => 21, 'B' => 0 } },
              { name: I18n.l(Date.parse('2024-09-01')), data: { 'A' => 42, 'B' => 12 } }
            ]
          )
        end
      end
    end

    context 'with a datetime attribute grouped by month' do
      let(:group_by_attribute) { 'created_at_by_month' }
      let(:raw_data) { { Date.parse('2024-09-01') => 42, Date.parse('2024-10-01') => 21 } }

      it 'returns data' do
        is_expected.to eq({ Date.parse('2024-09-01') => 42, Date.parse('2024-10-01') => 21 })
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'created_at_by_month' }
        let(:xaxis) { ['A', 'B'] }
        let(:raw_data) do
          {
            [Date.parse('2024-09-01'), 'A'] => 42,
            [Date.parse('2024-10-01'), 'A'] => 21,
            [Date.parse('2024-09-01'), 'B'] => 12
          }
        end

        it 'labels series name' do
          is_expected.to match(
            [
              { name: "#{I18n.t('date.month_names')[10]} 2024", data: { 'A' => 21, 'B' => 0 } },
              { name: "#{I18n.t('date.month_names')[9]} 2024", data: { 'A' => 42, 'B' => 12 } }
            ]
          )
        end
      end
    end

    # rubocop:disable Metrics/BlockLength
    context 'with a datetime attribute by hour of day' do
      let(:group_by_attribute) { 'created_at_hour_of_day' }
      let(:raw_data) { { 13 => 42, 5 => 4 } }

      it 'adds all missing hours' do
        is_expected.to eq_with_keys_order(
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

      context 'with #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'some_attribute' }
        let(:raw_data) { { ['A', 13] => 42, ['A', 5] => 4 } }

        it 'adds all missing days and labels keys' do
          is_expected.to match(
            [
              {
                name: 'A',
                data: eq_with_keys_order(
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
              }
            ]
          )
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'created_at_hour_of_day' }
        let(:xaxis) { ['A', 'B'] }
        let(:raw_data) { { [13, 'A'] => 42, [13, 'B'] => 21, [5, 'A'] => 4 } }

        it 'adds all missing keys' do
          is_expected.to match(
            [
              { name: 0, data: eq_with_keys_order({}) },
              { name: 1, data: eq_with_keys_order({}) },
              { name: 2, data: eq_with_keys_order({}) },
              { name: 3, data: eq_with_keys_order({}) },
              { name: 4, data: eq_with_keys_order({}) },
              { name: 5, data: eq_with_keys_order({ 'A' => 4, 'B' => 0 }) },
              { name: 6, data: eq_with_keys_order({}) },
              { name: 7, data: eq_with_keys_order({}) },
              { name: 8, data: eq_with_keys_order({}) },
              { name: 9, data: eq_with_keys_order({}) },
              { name: 10, data: eq_with_keys_order({}) },
              { name: 11, data: eq_with_keys_order({}) },
              { name: 12, data: eq_with_keys_order({}) },
              { name: 13, data: eq_with_keys_order({ 'A' => 42, 'B' => 21 }) },
              { name: 14, data: eq_with_keys_order({}) },
              { name: 15, data: eq_with_keys_order({}) },
              { name: 16, data: eq_with_keys_order({}) },
              { name: 17, data: eq_with_keys_order({}) },
              { name: 18, data: eq_with_keys_order({}) },
              { name: 19, data: eq_with_keys_order({}) },
              { name: 20, data: eq_with_keys_order({}) },
              { name: 21, data: eq_with_keys_order({}) },
              { name: 22, data: eq_with_keys_order({}) },
              { name: 23, data: eq_with_keys_order({}) }
            ]
          )
        end
      end
    end
    # rubocop:enable Metrics/BlockLength

    context 'with a datetime attribute by day of week' do
      let(:group_by_attribute) { 'created_at_day_of_week' }
      let(:raw_data) { { 2 => 4, 5 => 42 } }

      it 'adds all missing days and labels keys' do
        is_expected.to eq_with_keys_order(
          {
            I18n.t('date.day_names')[1] => 0,
            I18n.t('date.day_names')[2] => 4,
            I18n.t('date.day_names')[3] => 0,
            I18n.t('date.day_names')[4] => 0,
            I18n.t('date.day_names')[5] => 42,
            I18n.t('date.day_names')[6] => 0,
            I18n.t('date.day_names')[0] => 0
          }
        )
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }

        it 'does not sort labels keys' do
          is_expected.to eq_with_keys_order(
            {
              I18n.t('date.day_names')[1] => 0,
              I18n.t('date.day_names')[2] => 4,
              I18n.t('date.day_names')[3] => 0,
              I18n.t('date.day_names')[4] => 0,
              I18n.t('date.day_names')[5] => 42,
              I18n.t('date.day_names')[6] => 0,
              I18n.t('date.day_names')[0] => 0
            }
          )
        end
      end

      context 'with #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'some_attribute' }
        let(:raw_data) { { ['A', 5] => 42, ['A', 2] => 4 } }

        it 'adds all missing days and labels keys' do
          is_expected.to match(
            [
              {
                name: 'A',
                data: eq_with_keys_order(
                  {
                    I18n.t('date.day_names')[1] => 0,
                    I18n.t('date.day_names')[2] => 4,
                    I18n.t('date.day_names')[3] => 0,
                    I18n.t('date.day_names')[4] => 0,
                    I18n.t('date.day_names')[5] => 42,
                    I18n.t('date.day_names')[6] => 0,
                    I18n.t('date.day_names')[0] => 0
                  }
                )
              }
            ]
          )
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'created_at_day_of_week' }
        let(:xaxis) { ['A', 'B'] }
        let(:raw_data) { { [5, 'A'] => 42, [5, 'B'] => 21, [2, 'A'] => 4 } }

        it 'adds all missing keys' do
          is_expected.to match(
            [
              { name: I18n.t('date.day_names')[1], data: eq_with_keys_order({}) },
              { name: I18n.t('date.day_names')[2], data: eq_with_keys_order({ 'A' => 4, 'B' => 0 }) },
              { name: I18n.t('date.day_names')[3], data: eq_with_keys_order({}) },
              { name: I18n.t('date.day_names')[4], data: eq_with_keys_order({}) },
              { name: I18n.t('date.day_names')[5], data: eq_with_keys_order({ 'A' => 42, 'B' => 21 }) },
              { name: I18n.t('date.day_names')[6], data: eq_with_keys_order({}) },
              { name: I18n.t('date.day_names')[0], data: eq_with_keys_order({}) }
            ]
          )
        end
      end
    end

    context 'with an attribute needing more keys' do
      let(:group_by_attribute) { 'more_keys_attribute' }
      let(:raw_data) { { 2 => 42 } }

      it 'adds missing keys, sorted by value and keeping default order if value is 0' do
        is_expected.to eq_with_keys_order({ 2 => 42, 3 => 0, 1 => 0 })
      end

      context 'when #first is true' do
        let(:first) { true }

        it 'sorts in reverse' do
          is_expected.to eq_with_keys_order({ 3 => 0, 1 => 0, 2 => 42 })
        end
      end

      context 'when sort_by is "label"' do
        let(:sort_by) { 'label' }

        it 'adds missing keys, sorted by label' do
          is_expected.to eq_with_keys_order({ 3 => 0, 2 => 42, 1 => 0 })
        end

        context 'when #first is true' do
          let(:first) { true }

          it 'sorts in reverse' do
            is_expected.to eq_with_keys_order({ 1 => 0, 2 => 42, 3 => 0 })
          end
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'more_keys_attribute_b' }
        let(:xaxis) { [2, 3] }
        let(:raw_data) { { ['A', 2] => 42, ['B', 3] => 21, ['B', 2] => 12 } }

        it 'adds all missing series and all missing keys but only for series with the max value, in xaxis order' do
          is_expected.to match(
            [
              { name: 'C', data: eq_with_keys_order({}) },
              { name: 'B', data: eq_with_keys_order({ 2 => 12, 3 => 21, 1 => 0 }) },
              { name: 'A', data: eq_with_keys_order({ 2 => 42, 3 => 0, 1 => 0 }) }
            ]
          )
        end
      end
    end

    context 'with an attribute labelling keys' do
      let(:group_by_attribute) { 'sortable_label_key_attribute' }
      let(:raw_data) { { 'key_to_label' => 42, 'key_to_label_a' => 84 } }

      it 'labels keys' do
        is_expected.to eq_with_keys_order({ 'lebal_ot_yek' => 42, 'a_lebal_ot_yek' => 84 })
      end

      context 'with nil' do
        let(:raw_data) { { 'key_to_label' => 42, nil => 63, 'key_to_label_a' => 84 } }

        it 'labels nil key as "None"' do
          is_expected.to eq_with_keys_order({ 'lebal_ot_yek' => 42, I18n.t('none') => 63, 'a_lebal_ot_yek' => 84 })
        end
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }
        let(:raw_data) { { 'key_to_label' => 42, 'key_to_label_a' => 84 } }

        it 'sorts labelled keys' do
          is_expected.to eq_with_keys_order({ 'lebal_ot_yek' => 42, 'a_lebal_ot_yek' => 84 })
        end

        context 'with nil' do
          let(:raw_data) { { 'key_to_label' => 42, nil => 63, 'key_to_label_a' => 84 } }

          it 'puts "None" first' do
            is_expected.to eq_with_keys_order({ I18n.t('none') => 63, 'lebal_ot_yek' => 42, 'a_lebal_ot_yek' => 84 })
          end
        end

        context 'when #first is true' do
          let(:first) { true }

          it 'sorts labelled keys in reverse' do
            is_expected.to eq_with_keys_order({ 'a_lebal_ot_yek' => 84, 'lebal_ot_yek' => 42 })
          end

          context 'with nil' do
            let(:raw_data) { { 'key_to_label' => 42, nil => 63, 'key_to_label_a' => 84 } }

            it 'puts "None" last' do
              is_expected.to eq_with_keys_order({ 'a_lebal_ot_yek' => 84, 'lebal_ot_yek' => 42, I18n.t('none') => 63 })
            end
          end
        end

        context 'but #group_by_attribute is not sortable' do
          let(:group_by_attribute) { 'non_sortable_label_key_attribute' }
          let(:raw_data) { { 'key_to_label' => 84, nil => 63, 'key_to_label_a' => 42 } }

          it 'does not sort labelled keys' do
            is_expected.to eq_with_keys_order({ 'lebal_ot_yek' => 84, I18n.t('none') => 63, 'a_lebal_ot_yek' => 42 })
          end
        end
      end

      context 'having selects' do
        context 'with nil' do
          let(:group_by_attribute) { 'custom_label_attribute' }
          let(:raw_data) do
            {
              ['Object 1', 'A'] => 126,
              ['Object 2', nil] => 105,
              [nil, 'B'] => 84,
              [nil, nil] => 63
            }
          end

          it 'labels nil keys as "None"' do
            is_expected.to eq_with_keys_order(
              {
                'Object 1 (A)' => 126,
                'Object 2 ()' => 105,
                ' (B)' => 84,
                I18n.t('none') => 63
              }
            )
          end

          context 'when #sort_by is "label"' do
            let(:sort_by) { 'label' }

            it 'labels nil keys as "None"' do
              is_expected.to eq_with_keys_order(
                {
                  I18n.t('none') => 63,
                  'Object 2 ()' => 105,
                  'Object 1 (A)' => 126,
                  ' (B)' => 84
                }
              )
            end
          end

          context 'when custom #nil_key?' do
            let(:group_by_attribute) { 'custom_label_attribute_b' }
            let(:raw_data) do
              {
                ['Object 1', 'A'] => 126,
                ['Object 2', nil] => 105,
                [nil, 'B'] => 84
              }
            end

            it 'labels nil keys as "None"' do
              is_expected.to eq_with_keys_order(
                {
                  'Object 1 [A]' => 126,
                  'Object 2 []' => 105,
                  I18n.t('none') => 84
                }
              )
            end

            context 'when #sort_by is "label"' do
              let(:sort_by) { 'label' }

              it 'labels nil keys as "None"' do
                is_expected.to eq_with_keys_order(
                  {
                    I18n.t('none') => 84,
                    'Object 2 []' => 105,
                    'Object 1 [A]' => 126
                  }
                )
              end
            end
          end
        end
      end

      context 'needing sort before labelling' do
        let(:group_by_attribute) { 'custom_label_numeric_attribute' }

        context 'when #sort_by is "label"' do
          let(:sort_by) { 'label' }
          let(:first) { true }
          let(:raw_data) { { 1 => 2, 2 => 3, 10 => 42 } }

          it 'labels keys and sort in numeric order' do
            is_expected.to eq_with_keys_order({ 'Level 1' => 2, 'Level 2' => 3, 'Level 10' => 42 })
          end
        end
      end

      context 'as #subgroup_by_attribute' do
        let(:subgroup_by_attribute) { 'sortable_label_key_attribute_b' }
        let(:xaxis) { ['key_to_label_a', 'key_to_label'] }
        let(:raw_data) do
          {
            ['seires', 'key_to_label_a'] => 84,
            ['seires A', 'key_to_label'] => 63,
            ['seires', 'key_to_label'] => 42,
            ['seires A', 'key_to_label_a'] => 21
          }
        end

        it 'labels series names' do
          is_expected.to match(
            [
              { name: 'series', data: eq_with_keys_order({ 'a_lebal_ot_yek' => 84, 'lebal_ot_yek' => 42 }) },
              { name: 'A series', data: eq_with_keys_order({ 'a_lebal_ot_yek' => 21, 'lebal_ot_yek' => 63 }) }
            ]
          )
        end

        context 'with nil' do
          let(:xaxis) { ['key_to_label', 'key_to_label_a'] }
          let(:raw_data) do
            {
              [nil, 'key_to_label'] => 105,
              ['seires', 'key_to_label_a'] => 84,
              ['seires A', 'key_to_label'] => 63,
              ['seires', 'key_to_label'] => 42,
              ['seires A', 'key_to_label_a'] => 21
            }
          end

          it 'labels nil key as "None", "None" being first' do
            is_expected.to match(
              [
                { name: I18n.t('none'), data: eq_with_keys_order({ 'lebal_ot_yek' => 105, 'a_lebal_ot_yek' => 0 }) },
                { name: 'series', data: eq_with_keys_order({ 'lebal_ot_yek' => 42, 'a_lebal_ot_yek' => 84 }) },
                { name: 'A series', data: eq_with_keys_order({ 'lebal_ot_yek' => 63, 'a_lebal_ot_yek' => 21 }) }
              ]
            )
          end
        end

        context 'when #sort_by is "label"' do
          let(:sort_by) { 'label' }

          it 'labels series names' do
            is_expected.to match(
              [
                { name: 'series', data: eq_with_keys_order({ 'lebal_ot_yek' => 42, 'a_lebal_ot_yek' => 84 }) },
                { name: 'A series', data: eq_with_keys_order({ 'lebal_ot_yek' => 63, 'a_lebal_ot_yek' => 21 }) }
              ]
            )
          end
        end

        context 'when #subgroup_first is true' do
          let(:subgroup_first) { true }

          it 'sorts labelled series in reverse' do
            is_expected.to match(
              [
                { name: 'A series', data: eq_with_keys_order({ 'a_lebal_ot_yek' => 21, 'lebal_ot_yek' => 63 }) },
                { name: 'series', data: eq_with_keys_order({ 'a_lebal_ot_yek' => 84, 'lebal_ot_yek' => 42 }) }
              ]
            )
          end

          context 'with nil' do
            let(:xaxis) { ['key_to_label', 'key_to_label_a'] }
            let(:raw_data) do
              {
                [nil, 'key_to_label'] => 105,
                ['seires', 'key_to_label_a'] => 84,
                ['seires A', 'key_to_label'] => 63,
                ['seires', 'key_to_label'] => 42,
                ['seires A', 'key_to_label_a'] => 21
              }
            end

            it 'labels nil key as "None", "None" being last' do
              is_expected.to match(
                [
                  { name: 'A series', data: eq_with_keys_order({ 'lebal_ot_yek' => 63, 'a_lebal_ot_yek' => 21 }) },
                  { name: 'series', data: eq_with_keys_order({ 'lebal_ot_yek' => 42, 'a_lebal_ot_yek' => 84 }) },
                  { name: I18n.t('none'), data: eq_with_keys_order({ 'lebal_ot_yek' => 105, 'a_lebal_ot_yek' => 0 }) }
                ]
              )
            end
          end
        end

        context 'when there are multiple values for each dimension' do
          let(:group_by_attribute) { 'custom_label_attribute' }
          let(:subgroup_by_attribute) { 'custom_label_attribute_b' }
          let(:xaxis) { [['Object 1', 'A'], ['Object 2', 'Z']] }
          let(:raw_data) do
            {
              ['Series 1', 'AA', 'Object 1', 'A'] => 84,
              ['Series 1', 'AA', 'Object 2', 'Z'] => 63,
              ['Series 2', 'ZZ', 'Object 1', 'A'] => 42,
              ['Series 2', 'ZZ', 'Object 2', 'Z'] => 21
            }
          end

          it 'correctly labels keys and series names' do
            is_expected.to match(
              [
                { name: 'Series 2 [ZZ]', data: eq_with_keys_order({ 'Object 1 (A)' => 42, 'Object 2 (Z)' => 21 }) },
                { name: 'Series 1 [AA]', data: eq_with_keys_order({ 'Object 1 (A)' => 84, 'Object 2 (Z)' => 63 }) }
              ]
            )
          end

          context 'with nil' do
            let(:xaxis) { [['Object 1', 'A'], ['Object 2', nil], [nil, nil], ['Object 2', 'Z']] }
            let(:raw_data) do
              {
                ['Series 1', 'AA', 'Object 1', 'A'] => 126,
                ['Series 1', 'AA', 'Object 2', nil] => 105,
                ['Series 2', 'ZZ', 'Object 1', 'A'] => 84,
                ['Series 2', 'ZZ', nil, nil] => 63,
                [nil, 'XX', 'Object 1', 'A'] => 42,
                [nil, 'XX', 'Object 2', 'Z'] => 21
              }
            end

            # rubocop:disable Layout/LineLength
            it 'label nil keys as "None", according to attribute definition' do
              is_expected.to match(
                [
                  { name: I18n.t('none'), data: eq_with_keys_order({ 'Object 1 (A)' => 42, 'Object 2 ()' => 0, I18n.t('none') => 0, 'Object 2 (Z)' => 21 }) },
                  { name: 'Series 2 [ZZ]', data: eq_with_keys_order({ 'Object 1 (A)' => 84, 'Object 2 ()' => 0, I18n.t('none') => 63, 'Object 2 (Z)' => 0 }) },
                  { name: 'Series 1 [AA]', data: eq_with_keys_order({ 'Object 1 (A)' => 126, 'Object 2 ()' => 105, I18n.t('none') => 0, 'Object 2 (Z)' => 0 }) }
                ]
              )
            end
            # rubocop:enable Layout/LineLength
          end
        end
      end
    end

    context 'with an attribute labelling keys for series only' do
      let(:group_by_attribute) { 'label_series_attribute' }
      let(:raw_data) { { 2 => 42, 0 => 21 } }

      it 'does not label keys' do
        is_expected.to eq_with_keys_order({ 2 => 42, 0 => 21 })
      end

      context 'as #subgroup_by_attribute' do
        let(:group_by_attribute) { 'some_attribute' }
        let(:subgroup_by_attribute) { 'label_series_attribute' }
        let(:xaxis) { ['B', 'A'] }
        let(:raw_data) { { [2, 'B'] => 84, [2, 'A'] => 42, [10, 'A'] => 21 } }

        it 'adds all missing keys, sorted by value' do
          is_expected.to match(
            [
              { name: 'Level 10', data: eq_with_keys_order({ 'B' => 0, 'A' => 21 }) },
              { name: 'Level 2', data: eq_with_keys_order({ 'B' => 84, 'A' => 42 }) }
            ]
          )
        end
      end
    end

    context 'when #display_percent is true' do
      let(:display_percent) { true }
      let(:raw_data) { { '1' => 1, '2' => 3, '3' => 0 } }

      it 'computes percents' do
        is_expected.to eq_with_keys_order({ '1' => 25, '2' => 75, '3' => 0 })
      end

      context 'when data contains nil values' do
        let(:raw_data) { { '1' => 1, '2' => 3, '3' => nil } }

        it 'computes percents by replacing nil with 0' do
          is_expected.to eq_with_keys_order({ '1' => 25, '2' => 75, '3' => 0 })
        end
      end

      context 'when data is all 0 or nil' do
        let(:raw_data) { { '1' => 0, '2' => nil, '3' => 0 } }

        it 'computes percents with all values being 0' do
          is_expected.to eq_with_keys_order({ '1' => 0, '2' => 0, '3' => 0 })
        end
      end
    end
  end
  # rubocop:enable Style/WordArray

  describe '#empty?' do
    subject { chart.empty? }

    before { allow(chart).to receive(:data).and_return(data) }

    context 'when data is empty' do
      let(:data) { {} }
      it { is_expected.to eq(true) }
    end

    context 'when data only contains 0 or nil' do
      let(:data) { { 'A' => 0, 'B' => nil } }
      it { is_expected.to eq(true) }
    end

    context 'with data' do
      let(:data) { { 'A' => 42, 'B' => 0, 'C' => nil } }
      it { is_expected.to eq(false) }
    end

    context 'with #subgroup_by_attribute' do
      let(:subgroup_by_attribute) { 'some_other_attribute' }

      context 'when data is empty' do
        let(:data) { [] }
        it { is_expected.to eq(true) }
      end

      context 'when data is 1 series being empty' do
        let(:data) { [{ name: 'S1', data: {} }] }
        it { is_expected.to eq(true) }
      end

      context 'when data is 1 series containing only 0 or nil' do
        let(:data) { [{ name: 'S1', data: { 'A' => 0, 'B' => nil } }] }
        it { is_expected.to eq(true) }
      end

      context 'when data is 1 empty series and 1 series with data' do
        let(:data) { [{ name: 'S1', data: {} }, { name: 'S2', data: { 'A' => 42, 'B' => 0, 'C' => nil } }] }
        it { is_expected.to eq(false) }
      end

      context 'with data' do
        let(:data) { [{ name: 'S1', data: { 'A' => 21 } }, { name: 'S2', data: { 'A' => 42, 'B' => 0, 'C' => nil } }] }
        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#to_chartkick' do
    subject { chart.to_chartkick(view_context) }

    let(:view_context) { double }
    let(:data) { double }

    before { allow(chart).to receive(:data).and_return(data) }

    context 'when #type is line' do
      context 'when #group_by_attribute is simple' do
        it do
          expect(view_context).to receive(:line_chart).with(data, a_hash_including(discrete: true))
          subject
        end

        context 'with #display_percent is true' do
          let(:display_percent) { true }

          it do
            expect(view_context).to(
              receive(:line_chart).with(data, a_hash_including(discrete: true, suffix: '%', round: 2))
            )
            subject
          end
        end
      end

      context 'when #group_by_attribute is numeric' do
        let(:group_by_attribute) { 'some_numeric_attribute' }

        it do
          expect(view_context).to receive(:line_chart).with(data, any_args)
          subject
        end
      end

      context 'when #group_by_attribute is a datetime' do
        let(:group_by_attribute) { 'created_at' }

        it do
          expect(view_context).to receive(:line_chart).with(data, any_args)
          subject
        end
      end

      context 'when #group_by_attribute is a datetime grouped by week' do
        let(:group_by_attribute) { 'created_at_by_week' }

        it do
          expect(view_context).to receive(:line_chart).with(data, any_args)
          subject
        end
      end

      context 'when #group_by_attribute is a datetime grouped by month' do
        let(:group_by_attribute) { 'created_at_by_month' }

        it do
          expect(view_context).to receive(:line_chart).with(data, any_args)
          subject
        end
      end

      context 'when #group_by_attribute is a datetime by hour of day' do
        let(:group_by_attribute) { 'created_at_hour_of_day' }

        it do
          expect(view_context).to receive(:line_chart).with(data, hash_including(discrete: true))
          subject
        end
      end

      context 'when #group_by_attribute is a datetime by day of week' do
        let(:group_by_attribute) { 'created_at_day_of_week' }

        it do
          expect(view_context).to receive(:line_chart).with(data, hash_including(discrete: true))
          subject
        end
      end

      context 'when #group_by_attribute is a date' do
        let(:group_by_attribute) { 'date' }

        it do
          expect(view_context).to receive(:line_chart).with(data, any_args)
          subject
        end
      end

      context 'when #group_by_attribute is a date grouped by week' do
        let(:group_by_attribute) { 'date_by_week' }

        it do
          expect(view_context).to receive(:line_chart).with(data, any_args)
          subject
        end
      end

      context 'when #group_by_attribute is a date grouped by month' do
        let(:group_by_attribute) { 'date_by_month' }

        it do
          expect(view_context).to receive(:line_chart).with(data, any_args)
          subject
        end
      end

      context 'when #group_by_attribute is a date grouped by day of week' do
        let(:group_by_attribute) { 'date_day_of_week' }

        it do
          expect(view_context).to receive(:line_chart).with(data, hash_including(discrete: true))
          subject
        end
      end

      context 'when #group_by_attribute needs more keys' do
        let(:group_by_attribute) { 'more_keys_attribute' }

        it do
          expect(view_context).to receive(:line_chart).with(data, hash_including(discrete: true))
          subject
        end
      end
    end

    context 'when #type is pie' do
      let(:chart_type) { 'pie' }

      context 'when #group_by_attribute is simple' do
        let(:group_by_attribute) { 'some_attribute' }

        it do
          expect(view_context).to receive(:pie_chart).with(data, hash_including(discrete: true))
          subject
        end
      end
    end

    context 'when #type is column' do
      let(:chart_type) { 'column' }

      context 'when #group_by_attribute is simple' do
        let(:group_by_attribute) { 'some_attribute' }

        it do
          expect(view_context).to receive(:column_chart).with(data, hash_including(discrete: true, stacked: true))
          subject
        end
      end
    end
  end
end
