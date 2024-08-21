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
      group_by_attribute 'created_at', :datetime, sub_types: %i[hour_of_day day_of_week]
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

    context 'when chart_type is present' do
      before { search.chart_type = 'line' }

      it { is_expected.to allow_value('some_attribute').for(:group_by_attribute) }
      it { is_expected.to allow_value('created_at').for(:group_by_attribute) }
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
          period: nil
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
            period: nil
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
              period: Period.new(from: start_at, to: end_at)
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
    group_by_attribute 'some_numeric_attribute', :numeric
    group_by_attribute 'created_at', :datetime, sub_types: %i[hour_of_day day_of_week]
    group_by_attribute 'custom_label_attribute',
                       :string,
                       joins: { relation: { other_relation: {} }, another_relation: {} },
                       selects: %w[other_relations.name another_relations.label]
    group_by_attribute 'more_keys_attribute', :numeric, keys: [1, 2, 3]
    group_by_attribute 'sortable_label_key_attribute', :string do
      def label(key)
        key.reverse
      end
    end
    group_by_attribute 'non_sortable_label_key_attribute', :string, sortable: false do
      def label(key)
        key.reverse
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
      period: period
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
  let(:period) { nil }

  before { allow(models).to receive(:column_alias_for) { |arg| Search::Save.all.send(:column_alias_for, arg) } }

  describe '#raw_data' do
    subject { chart.raw_data }

    context 'with a simple attribute' do
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

        context 'when #first is true' do
          let(:first) { true }

          it do
            expect(models).to receive(:group).with('some_attribute').and_return(models)
            expect(models).to receive(:order).with('some_attribute' => :asc).and_return(models)
            expect(models).to receive(:limit).with(10).and_return(models)
            expect(models).to receive(:count).with(:id)
            subject
          end
        end
      end
    end

    context 'with a datetime attribute' do
      let(:group_by_attribute) { 'created_at' }

      it do
        expect(models).to receive(:group_by_day).with('created_at', last: 10, range: nil).and_return(models)
        expect(models).to receive(:count).with(:id)
        subject
      end

      context 'when #first is true' do
        let(:first) { true }

        it do
          expect(models).to receive(:group_by_day).with('created_at', last: 10, range: nil).and_return(models)
          expect(models).to receive(:count).with(:id)
          subject
        end
      end

      context 'when #top_count is 100' do
        let(:top_count) { 100 }

        it do
          expect(models).to receive(:group_by_day).with('created_at', last: 100, range: nil).and_return(models)
          expect(models).to receive(:count).with(:id)
          subject
        end
      end

      context 'with period' do
        let(:period) { Period.new(from: Time.zone.yesterday, to: Time.zone.tomorrow) }

        it do
          expect(models).to receive(:group_by_day).with('created_at', last: 10, range: period).and_return(models)
          expect(models).to receive(:count).with(:id)
          subject
        end
      end
    end

    context 'with a datetime attribute by hour of day' do
      let(:group_by_attribute) { 'created_at_hour_of_day' }

      it do
        expect(models).to receive(:group_by_hour_of_day).with('created_at').and_return(models)
        expect(models).to receive(:count).with(:id)
        subject
      end
    end

    context 'with a datetime attribute by day of week' do
      let(:group_by_attribute) { 'created_at_day_of_week' }

      it do
        expect(models).to receive(:group_by_day_of_week).with('created_at').and_return(models)
        expect(models).to receive(:count).with(:id)
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
        expect(models).to receive(:order).with(count_id: :desc).and_return(models)
        expect(models).to receive(:limit).with(10).and_return(models)
        expect(models).to receive(:count).with(:id)
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
            receive(:select).with('other_relations.name', 'another_relations.label').and_return(models)
          )
          expect(models).to(
            receive(:group).with('other_relations.name', 'another_relations.label').and_return(models)
          )
          expect(models).to(
            receive(:order).with('other_relations.name' => :desc, 'another_relations.label' => :desc).and_return(models)
          )
          expect(models).to receive(:limit).with(10).and_return(models)
          expect(models).to receive(:count).with(:id)
          subject
        end

        context 'when #first is true' do
          let(:first) { true }

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
              receive(:order).with('other_relations.name' => :asc, 'another_relations.label' => :asc).and_return(models)
            )
            expect(models).to receive(:limit).with(10).and_return(models)
            expect(models).to receive(:count).with(:id)
            subject
          end
        end
      end
    end

    context 'when #aggregate_operation is "sum"' do
      let(:aggregate_operation) { 'sum' }
      let(:aggregate_attribute) { 'some_numeric_attribute' }

      context 'when #aggregate_attribute is numeric' do
        it do
          expect(models).to receive(:group).with('some_attribute').and_return(models)
          expect(models).to(
            receive(:order).with('sum_some_numeric_attribute' => :desc).and_return(models)
          )
          expect(models).to receive(:limit).with(10).and_return(models)
          expect(models).to receive(:sum).with('some_numeric_attribute')
          subject
        end
      end

      context 'when #aggregate_attribute has a custom definition' do
        let(:aggregate_attribute) { 'custom_aggregate_attribute' }

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

    context 'when #aggregate_operation is "average"' do
      let(:aggregate_operation) { 'average' }
      let(:aggregate_attribute) { 'some_numeric_attribute' }

      it do
        expect(models).to receive(:group).with('some_attribute').and_return(models)
        expect(models).to(
          receive(:order).with('average_some_numeric_attribute' => :desc).and_return(models)
        )
        expect(models).to receive(:limit).with(10).and_return(models)
        expect(models).to receive(:average).with('some_numeric_attribute')
        subject
      end
    end
  end

  describe '#data' do
    subject { chart.data }

    let(:raw_data) { {} }

    before { expect(chart).to receive(:raw_data).and_return(raw_data) }

    context 'with a simple attribute' do
      let(:raw_data) { { 'A' => 1, 'C' => 2, 'B' => 3 } }

      it 'returns data sorted by value' do
        is_expected.to eq_with_keys_order({ 'A' => 1, 'C' => 2, 'B' => 3 })
      end

      context 'when there is nil key' do
        let(:raw_data) { { 'A' => 1, 'C' => 2, 'B' => 3, nil => 4 } }

        it 'replaces nil by "None"' do
          is_expected.to eq_with_keys_order({ 'A' => 1, 'C' => 2, 'B' => 3, I18n.t('none') => 4 })
        end
      end

      context 'when #sort_by is "label"' do
        let(:sort_by) { 'label' }
        let(:raw_data) { { 'A' => 1, 'B' => 3, 'C' => 2, nil => 4 } }

        it 'replaces nil by "None"' do
          is_expected.to eq_with_keys_order({ 'A' => 1, 'B' => 3, 'C' => 2, I18n.t('none') => 4 })
        end
      end
    end

    context 'with a datetime attribute by hour of day' do
      let(:group_by_attribute) { 'created_at_hour_of_day' }
      let(:raw_data) { { 5 => 4, 13 => 42 } }

      it 'adds all missing hours' do # rubocop:disable Metrics/BlockLength
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
    end

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
    end

    context 'with an attribute needing more keys' do
      let(:group_by_attribute) { 'more_keys_attribute' }
      let(:raw_data) { { 2 => 42 } }

      it 'adds missing keys, sorted by value' do
        is_expected.to eq_with_keys_order({ 2 => 42, 1 => 0, 3 => 0 })
      end

      context 'when #first is true' do
        let(:first) { true }

        it 'sorts in reverse' do
          is_expected.to eq_with_keys_order({ 1 => 0, 3 => 0, 2 => 42 })
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
    end

    context 'when #display_percent is true' do
      let(:display_percent) { true }
      let(:raw_data) { { '1' => 1, '2' => 3, '3' => 0 } }

      it 'computes percents' do
        is_expected.to eq_with_keys_order({ '1' => 25, '2' => 75, '3' => 0 })
      end

      context 'when data is all 0' do
        let(:raw_data) { { '1' => 0, '2' => 0, '3' => 0 } }

        it 'computes percents' do
          is_expected.to eq_with_keys_order({ '1' => 0, '2' => 0, '3' => 0 })
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
      context 'when #group_by_attribute is simple' do
        it do
          expect(view_context).to receive(:line_chart).with(data, discrete: true)
          subject
        end

        context 'with #display_percent is true' do
          let(:display_percent) { true }

          it do
            expect(view_context).to receive(:line_chart).with(data, discrete: true, suffix: '%')
            subject
          end
        end
      end

      context 'when #group_by_attribute is numeric' do
        let(:group_by_attribute) { 'some_numeric_attribute' }

        it do
          expect(view_context).to receive(:line_chart).with(data, {})
          subject
        end
      end

      context 'when #group_by_attribute is a datetime' do
        let(:group_by_attribute) { 'created_at' }

        it do
          expect(view_context).to(
            receive(:line_chart).with(
              data,
              {
                library: {
                  scales: {
                    x: {
                      time: {
                        displayFormats: {
                          day: 'dd/MM/yyyy'
                        }
                      }
                    }
                  }
                }
              }
            )
          )
          subject
        end
      end

      context 'when #group_by_attribute is a datetime by hour of day' do
        let(:group_by_attribute) { 'created_at_hour_of_day' }

        it do
          expect(view_context).to receive(:line_chart).with(data, discrete: true)
          subject
        end
      end

      context 'when #group_by_attribute is a datetime by day of week' do
        let(:group_by_attribute) { 'created_at_day_of_week' }

        it do
          expect(view_context).to receive(:line_chart).with(data, discrete: true)
          subject
        end
      end

      context 'when #group_by_attribute needs more keys' do
        let(:group_by_attribute) { 'more_keys_attribute' }

        it do
          expect(view_context).to receive(:line_chart).with(data, discrete: true)
          subject
        end
      end
    end

    context 'when #type is pie' do
      let(:chart_type) { 'pie' }

      context 'when #group_by_attribute is a datetime' do
        let(:group_by_attribute) { 'created_at' }

        it do
          expect(view_context).to receive(:pie_chart).with(data, {})
          subject
        end
      end
    end

    context 'when #type is column' do
      let(:chart_type) { 'column' }

      context 'when #group_by_attribute is a datetime' do
        let(:group_by_attribute) { 'created_at' }

        it do
          expect(view_context).to(
            receive(:column_chart).with(
              data,
              {
                library: {
                  scales: {
                    x: {
                      time: {
                        displayFormats: {
                          day: 'dd/MM/yyyy'
                        }
                      }
                    }
                  }
                }
              }
            )
          )
          subject
        end
      end
    end
  end
end
