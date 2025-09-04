# frozen_string_literal: true

RSpec.describe ApplicationStoreModel do
  describe 'inheritance' do
    let(:simple_class) do
      Class.new(described_class) do
        attribute :attr1
        attribute :attr2, default: 42
      end
    end
    let(:base_class) do
      Class.new(described_class)
    end
    let(:inherit_from_base_class) do
      Class.new(base_class)
    end
    let(:abstract_base_class) do
      Class.new(described_class) do
        self.abstract_class = true
      end
    end
    let(:inherit_from_abstract_base_class) do
      Class.new(abstract_base_class)
    end
    let(:abstract_inherit_from_inherit_from_base_class) do
      Class.new(inherit_from_base_class) do
        self.abstract_class = true
      end
    end
    let(:inherit_from_abstract_base_class2) do
      Class.new(abstract_base_class)
    end
    let(:inherit_from_inherit_from_abstract_base_class) do
      Class.new(inherit_from_abstract_base_class2)
    end
    let(:abstract_base_class_with_type) do
      Class.new(described_class) do
        self.abstract_class = true
        attribute :type, :string
      end
    end
    let(:inherit_from_abstract_base_class_with_type) do
      Class.new(abstract_base_class_with_type)
    end

    before do
      stub_const('SimpleClass', simple_class)
      stub_const('BaseClass', base_class)
      stub_const('InheritFromBaseClass', inherit_from_base_class)
      stub_const('AbstractBaseClass', abstract_base_class)
      stub_const('InheritFromAbstractBaseClass', inherit_from_abstract_base_class)
      stub_const('AbstractInheritFromInheritFromBaseClass', abstract_inherit_from_inherit_from_base_class)
      stub_const('InheritFromAbstractBaseClass2', inherit_from_abstract_base_class2)
      stub_const('InheritFromInheritFromAbstractBaseClass', inherit_from_inherit_from_abstract_base_class)
      stub_const('AbstractBaseClassWithType', abstract_base_class_with_type)
      stub_const('InheritFromAbstractBaseClassWithType', inherit_from_abstract_base_class_with_type)
    end

    describe 'type attribute' do
      it 'does not add type column to simple class' do
        expect(abstract_base_class.attribute_names).not_to include('type')
      end

      it 'adds type column to base class' do
        expect(base_class.attribute_names).to include('type')
      end

      it 'class inheriting from base class inherits type column' do
        expect(inherit_from_base_class.attribute_names).to include('type')
      end

      it 'does not add type column to abstract base class' do
        expect(abstract_base_class.attribute_names).not_to include('type')
      end

      it 'adds type column to class inheriting from abstract base class' do
        expect(inherit_from_abstract_base_class.attribute_names).not_to include('type')
      end

      it 'class inheriting from class inheriting from abstract base class inherits type column' do
        expect(inherit_from_inherit_from_abstract_base_class.attribute_names).to include('type')
      end

      it 'abstract base class with type defines type column' do
        expect(abstract_base_class_with_type.attribute_names).to include('type')
      end
    end

    describe 'setting of type attribute' do
      it 'does not fill type of instance of simple class' do
        expect(simple_class.new.as_json['type']).to be_nil
      end

      it 'does not fill type of instance of base class' do
        expect(base_class.new.type).to be_nil
      end

      it 'fills type of instance of class inheriting from base class' do
        expect(inherit_from_base_class.new.type).to eq('InheritFromBaseClass')
      end

      it 'does not override type already provided in attributes' do
        expect(inherit_from_base_class.new({ 'type' => 'Weird' }).type).to eq('Weird')
      end

      it 'does not fill type of instance of abstract base class' do
        expect(abstract_base_class.new.as_json['type']).to be_nil
      end

      it 'does not fill type of instance of class inheriting from abstract base class' do
        expect(inherit_from_abstract_base_class.new.as_json['type']).to be_nil
      end

      it 'fills type of instance of class inheriting from class inheriting from abstract base class' do
        expect(inherit_from_inherit_from_abstract_base_class.new.type).to eq('InheritFromInheritFromAbstractBaseClass')
      end

      it 'fills type of instance of abstract class inheriting from class inheriting from base class' do
        expect(abstract_inherit_from_inherit_from_base_class.new.type).to eq('AbstractInheritFromInheritFromBaseClass')
      end

      it 'does not fill type of instance of abstract base class with type' do
        expect(abstract_base_class_with_type.new.as_json['type']).to be_nil
      end

      it 'does not fill type of instance of class inheriting from abstract base class with type' do
        expect(inherit_from_abstract_base_class_with_type.new.as_json['type']).to be_nil
      end
    end

    describe 'loading from JSON' do
      it 'loads correct class if JSON has no type' do
        expect(inherit_from_base_class.to_type.cast_value({})).to be_a(inherit_from_base_class)
      end

      it 'loads correct descendant of class specified in JSON type' do
        expect(
          base_class.one_of_descendants.to_type.cast_value({ 'type' => 'InheritFromBaseClass' })
        ).to(
          be_a(inherit_from_base_class)
        )
      end

      it 'loads base class if JSON has no type' do
        expect(base_class.one_of_descendants.to_type.cast_value({})).to be_a(base_class)
      end

      it 'loads base class if JSON has incorrect type' do
        expect(
          base_class.one_of_descendants.to_type.cast_value({ 'type' => 'InheritFromAbstractBaseClass' })
        ).to(
          be_a(base_class)
        )
      end

      it 'loads correct descendant from abstract class specified in JSON type' do
        expect(
          abstract_base_class.one_of_descendants.to_type.cast_value({ 'type' => 'InheritFromAbstractBaseClass' })
        ).to(
          be_a(inherit_from_abstract_base_class)
        )
      end

      it 'loads correct descendant from abstract class with type specified in JSON type' do
        expect(
          abstract_base_class_with_type.one_of_descendants.to_type.cast_value({ 'type' => 'InheritFromAbstractBaseClassWithType' }) # rubocop:disable Layout/LineLength
        ).to(
          be_a(inherit_from_abstract_base_class_with_type)
        )
      end
    end

    # For some reason, the handling of hash and raw JSON is different in store model:
    #   - hash: extract_model_klass(value).to_type.cast_value(value.to_h)
    #   - raw JSON: extract_model_klass(value).new(value)
    describe 'loading from raw JSON' do
      it 'loads correct class if JSON has no type' do
        expect(inherit_from_base_class.to_type.cast_value({}.to_json)).to be_a(inherit_from_base_class)
      end

      it 'loads correct descendant of class specified in JSON type' do
        expect(
          base_class.one_of_descendants.to_type.cast_value({ 'type' => 'InheritFromBaseClass' }.to_json)
        ).to(
          be_a(inherit_from_base_class)
        )
      end

      it 'loads base class if JSON has no type' do
        expect(base_class.one_of_descendants.to_type.cast_value({})).to be_a(base_class)
      end

      it 'loads base class if JSON has incorrect type' do
        expect(
          base_class.one_of_descendants.to_type.cast_value({ 'type' => 'InheritFromAbstractBaseClass' }.to_json)
        ).to(
          be_a(base_class)
        )
      end

      # NOTE: see https://enroute.atlassian.net/browse/CHOUETTE-4855?focusedCommentId=57626
      it 'does not load correct descendant from abstract class specified in JSON type' do
        expect(
          abstract_base_class.one_of_descendants.to_type.cast_value({ 'type' => 'InheritFromAbstractBaseClass' }.to_json) # rubocop:disable Layout/LineLength
        ).not_to(
          be_a(inherit_from_abstract_base_class)
        )
      end

      it 'loads correct descendant from abstract class with type specified in JSON type' do
        expect(
          abstract_base_class_with_type.one_of_descendants.to_type.cast_value({ 'type' => 'InheritFromAbstractBaseClassWithType' }.to_json) # rubocop:disable Layout/LineLength
        ).to(
          be_a(inherit_from_abstract_base_class_with_type)
        )
      end
    end

    describe 'serialization' do
      def serialize(class_type, model)
        ActiveSupport::JSON.decode(class_type.serialize(model))
      end

      it 'serializes default values' do
        expect(
          serialize(simple_class.to_type, simple_class.new(attr1: 1))
        ).to eq(
          { 'attr1' => 1, 'attr2' => 42 }
        )
      end

      it 'does not serialize missing attributes' do
        expect(
          serialize(simple_class.to_type, simple_class.new(attr2: 2))
        ).to eq(
          { 'attr2' => 2 }
        )
      end

      it 'serializes type attribute' do
        expect(
          serialize(base_class.one_of_descendants.to_type, inherit_from_base_class.new)
        ).to eq(
          { 'type' => 'InheritFromBaseClass' }
        )
      end

      it 'serializes type attribute of descendant of abstract class with type from parent' do
        expect(
          serialize(
            abstract_base_class_with_type.one_of_descendants.to_type,
            inherit_from_abstract_base_class_with_type.new(type: 'InheritFromAbstractBaseClassWithType')
          )
        ).to eq(
          { 'type' => 'InheritFromAbstractBaseClassWithType' }
        )
      end

      it 'does not serialize type attribute of descendants of abstract class with type from same class' do
        expect(
          serialize(inherit_from_abstract_base_class_with_type.to_type, inherit_from_abstract_base_class_with_type.new)
        ).to eq(
          {}
        )
      end
    end
  end

  describe '#becomes' do
    subject { source.becomes(target_class) }

    let(:model_class) do
      Class.new(described_class) do
        attribute :name
        attribute :invalid_attribute
        validates :invalid_attribute, presence: true
      end
    end
    let(:base_class) do
      model_class = self.model_class
      Class.new(described_class) do
        attribute :common_attribute
        attribute :common_model, model_class.to_type
        attribute :common_invalid
        validates :common_invalid, presence: true
        validates :common_model, store_model: true
      end
    end
    let(:source_class) do
      model_class = self.model_class
      Class.new(base_class) do
        attribute :source_attribute
        attribute :source_model, model_class.to_type
        attribute :source_invalid
        validates :source_invalid, presence: true
        validates :source_model, store_model: true
      end
    end
    let(:target_class) do
      model_class = self.model_class
      Class.new(base_class) do
        attribute :target_attribute
        attribute :target_model, model_class.to_type
        attribute :target_invalid
        validates :target_invalid, presence: true
        validates :target_model, store_model: true
      end
    end
    let(:parent) { double(:parent) }
    let(:source) do
      source_class.new(
        common_attribute: 'common_attribute_value',
        common_model: { name: 'common_model_value' },
        source_attribute: 'source_attribute_value',
        source_model: { name: 'source_model_value' }
      ).tap do |source|
        source.parent = parent
      end
    end

    before { source.valid? }

    it 'instantiates target class' do
      is_expected.to be_a(target_class)
    end

    it 'copies parent' do
      expect(subject.parent).to eq(parent)
    end

    it 'copies common attributes' do
      is_expected.to have_attributes(common_attribute: 'common_attribute_value')
    end

    it 'copies common models' do
      expect(subject.common_model).to be_a(model_class)
      expect(subject.common_model.parent).to eq(subject)
      expect(subject.common_model.name).to eq('common_model_value')
    end

    it 'does not copy unknown attributes' do
      expect(subject.unknown_attributes).to be_empty
    end

    it 'does not set target attributes' do
      expect(subject.target_attribute).to be_nil
    end

    it 'does not set target models' do
      expect(subject.target_model).to be_nil
    end

    describe 'errors' do
      it 'copies errors' do
        expect(subject.errors.details).to(
          include({ common_invalid: [{ error: :blank }], common_model: [{ error: :invalid }] })
        )
      end

      it 'copies errors of models' do
        expect(subject.common_model.errors.details).to(
          eq({ invalid_attribute: [{ error: :blank }] })
        )
      end
    end
  end
end

describe ApplicationStoreModel::IntegerArrayType do
  subject(:type) { described_class.new }

  describe '#cast' do
    subject { type.cast(value) }

    context 'when value is an array of integers' do
      let(:value) { [1, 2, 3, 4] }

      it 'returns the same value unchanged' do
        is_expected.to eq([1, 2, 3, 4])
      end
    end

    context 'when value is an array of strings' do
      let(:value) { %w[1 2 3 4] }

      it 'casts each value of the array' do
        is_expected.to eq([1, 2, 3, 4])
      end
    end

    context 'when value is a string' do
      context 'when value is serialized array of integers' do
        let(:value) { '[1, 2, 3, 4]' }

        it 'unserializes the array' do
          is_expected.to eq([1, 2, 3, 4])
        end
      end

      context 'when value is serialized array of strings' do
        let(:value) { '["1", "2", "3", "4"]' }

        it 'unserialized the array and casts each value' do
          is_expected.to eq([1, 2, 3, 4])
        end
      end

      context 'when "null"' do
        let(:value) { 'null' }

        it 'returns nil' do
          is_expected.to eq(nil)
        end
      end
    end
  end
end
