RSpec.describe Search::Base do

  class self::Search < Search::Base
    attribute :name
    attr_accessor :context

    class Order < ::Search::Order
      attribute :name, column: 'column'
      attr_accessor :context
    end
  end

  let(:scope) { double }
  subject(:search) { self.class::Search.new scope }

  describe "initializer" do

    context "when params define a Search attribute (like search: { name: 'dummy' })" do
      subject { self.class::Search.new scope, search: { name: "dummy" } }

      it { is_expected.to have_attributes(name: "dummy")}
    end

    context "when params define a Search Order attribute (like search: { order: { name: 'desc' }})" do
      subject(:search) { self.class::Search.new scope, search: { order: { name: 'desc' } } }

      it { expect(search.order).to have_attributes(name: :desc) }
    end

    context "when context define a Search accessor (like { context: 'test' })" do
      subject { self.class::Search.new scope, {}, { context: "test" }}

      it { is_expected.to have_attributes(context: "test")}
    end

  end

  describe ".params" do

    subject { Search::Base.params given_params }

    context "when given params are nil" do
      let(:given_params) { nil }
      it { is_expected.to eq({}) }
    end

    context "when (legacy) 'sort' param is defined (like sort=name)" do
      let(:given_params) { { sort: "name" } }
      it { is_expected.to eq( order: { name: :asc } ) }
    end

    context "when (legacy) 'direction' param is defined (like sort=name & direction=desc)" do
      let(:given_params) { { sort: "name", direction: "desc" } }
      it { is_expected.to eq( order: { name: :desc } ) }
    end

    context "when (legacy) 'per_page' param is defined (like per_page=10)" do
      let(:given_params) { { per_page: "10" } }
      it { is_expected.to eq( { per_page: "10" } ) }
    end

    context "when (legacy) 'page' param is defined (like page=2)" do
      let(:given_params) { { page: "2" } }
      it { is_expected.to eq( { page: "2" } ) }
    end

  end

  describe "#scope" do
    subject { search.scope }
    it "is the scope used to create the Search" do
      is_expected.to be(scope)
    end
  end

  describe "#collection" do
    subject { search.collection }

    context "when the Search isn't valid" do
      let(:scope) { double none: double("None relation from scope") }

      before do
        allow(search).to receive(:valid?).and_return(false)
      end

      it { is_expected.to be(scope.none) }
    end

    context "when the Search is valid" do
      let(:query) { double scope: scope }

      before do
        allow(search).to receive(:valid?).and_return(true)
        allow(search).to receive(:query).and_return(query)

        allow(scope).to receive(:order).and_return(scope)
        allow(scope).to receive(:paginate).and_return(scope)
      end

      it "is the Query scope" do
        is_expected.to eq(query.scope)
      end

      it "is paginated with paginate attributes" do
        search.per_page = 42
        search.page = 7

        expect(scope).to receive(:paginate).with(per_page: 42, page: 7).and_return(scope)

        subject
      end

      it "is ordered with order hash" do
        allow(search.order).to receive(:order_hash).and_return(name: :desc)
        expect(scope).to receive(:order).with(search.order.order_hash).and_return(scope)

        subject
      end
    end

  end

  describe "#attributes=" do
    context "when a given key matches an defined attribute" do
      it "changes the attribute value" do
        expect { search.attributes = { name: "dummy" } ; }.to change(search, :name).to("dummy")
      end
    end

    context "when a given key matches a writer method but not a defined attribute" do
      it "doesn't change the Search" do
        expect { search.attributes = { context: "dummy" } }.to_not change(search, :context)
      end
    end

    context "when no given key/value matches an attribute" do
      subject { search.name = "dummy" }
      it "doesn't change the attribute value" do
        expect { search.attributes = {} ; }.to_not change(search, :name)
      end
    end
  end

  describe "#to_key" do
    subject { search.to_key }
    it { is_expected.to be_nil }
  end

  describe ".model_name" do
    subject { self.class::Search.model_name.to_s }

    # context "when the Search is a Controller subclass (like TestsController::Search)" do
    #   before { allow(self.class::Search).to receive(:name).and_return('TestsController::Search') }
    #   it { is_expected.to eq("Search::Tests") }
    # end

    context "by default" do
      it { is_expected.to eq("Search") }
    end
  end

  describe "per_page" do
    subject { search.per_page }

    context "when no value is defined" do
      it { is_expected.to eq(30) }
    end

    context "when per_page is defined with a non-numerical value" do
      before { search.per_page = 'abc' }
      it { is_expected.to eq(0) }
    end

    context "when per_page is defined with less than 1 (like 0)" do
      before { search.per_page = 0 }

      it "makes the Search invalid" do
        expect(search).to_not be_valid
      end
    end

    context "when per_page is defined with more than 100 (like 101)" do
      before { search.per_page = 101 }

      it "makes the Search invalid" do
        expect(search).to_not be_valid
      end
    end
  end

  describe "page" do
    subject { search.page }

    context "when page is defined with a non-numerical value" do
      before { search.page = 'abc' }
      it { is_expected.to eq(0) }
    end

    context "when page is defined with less than 0 (like -1)" do
      before { search.page = -1 }

      it "makes the Search invalid" do
        expect(search).to_not be_valid
      end
    end
  end

  describe "#paginate_attributes" do
    subject { search.paginate_attributes }

    context "per_page is 30 and page is 2" do
      before do
        search.per_page = 30
        search.page = 2
      end

      it { is_expected.to eq(per_page: 30, page: 2) }
    end
  end

  describe "#order" do
    subject { search.order }
    it "is an instance of the Search Order subclass" do
      is_expected.to be_an_instance_of(self.class::Search::Order)
    end
  end

  describe Search::Order do
    subject(:order) { self.class::Search::Order.new }

    describe "initializer" do
      context "when Order is created with attributes, like name: 'asc'" do
        subject(:order) { self.class::Search::Order.new name: 'asc' }
        it { is_expected.to have_attributes(name: :asc) }
      end
    end

    describe "#attributes=" do
      context "when a given key matches an defined attribute" do
        it "changes the attribute value" do
          expect { search.attributes = { name: "asc" } ; }.to change(search, :name).to("asc")
        end
      end

      context "when a given key matches a writer method but not a defined attribute" do
        it "doesn't change the Order" do
          expect { search.attributes = { context: "dummy" } }.to_not change(search, :context)
        end
      end

      context "when a given key doesn't match any writer method" do
        it "doesn't change the Order (or raise error)" do
          expect { search.attributes = { dummy: 42 } }.to_not raise_error
        end
      end
    end

    describe "attribute writer method" do
      Search::Order::Attribute::ASCENDANT_VALUES.each do |value|
        context "when the attribute value is #{value}" do
          it "change the attribute value to :asc" do
            expect { order.name = value }.to change(order, :name).to(:asc)
          end
        end
      end

      Search::Order::Attribute::DESCENDANT_VALUES.each do |value|
        context "when the attribute value is #{value}" do
          it "change the attribute value to :desc" do
            expect { order.name = value }.to change(order, :name).to(:desc)
          end
        end
      end
    end

    describe ".attributes" do
      subject { self.class::Search::Order.attributes }

      it "contains all defined attributes" do
        is_expected.to contain_exactly(an_object_having_attributes(name: :name))
      end
    end

    describe "#order_hash" do
      subject { order.order_hash }

      context "when attribute name is :asc (and column 'column')" do
        before { order.name = :asc }
        it { is_expected.to eq('column' => :asc) }
      end
      context "when attribute name is :desc (and column 'column')" do
        before { order.name = :desc }
        it { is_expected.to eq('column' => :desc) }
      end
      context "when attribute name is not defined" do
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

    describe ".attribute" do
      context "when another Order is defined" do
        before do
          Class.new(::Search::Order) do
            attribute :other, default: :desc
          end
        end

        it "defines attributes specific the Order class" do
          order_class = Class.new(::Search::Order) do
            attribute :dummy
          end
          expect(order_class.attributes).to contain_exactly(an_object_having_attributes(name: :dummy))
        end

        it "defines defaults specific the Order class" do
          order_class = Class.new(::Search::Order) do
            attribute :dummy, default: :desc
          end
          expect(order_class.defaults).to eq(dummy: :desc)
        end

      end
    end
  end
end
