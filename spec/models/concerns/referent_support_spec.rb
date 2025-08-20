# frozen_string_literal: true

RSpec.describe ReferentSupport do
  with_model :WithReferent do
    table do |t|
      t.references :referent
      t.boolean :is_referent, default: false
    end

    model do
      include ReferentSupport

      def inspect
        if referent?
          "#<Referent id: #{id}>"
        else
          "#<Particular id: #{id}, referent_id: #{referent_id}>"
        end
      end
    end
  end

  def create_referent
    WithReferent.create! is_referent: true
  end

  def create_particular(referent = nil)
    WithReferent.create! referent: referent
  end

  describe 'validations' do
    context 'when being a referent and having a referent' do
      it 'has error when a referent gets a referent' do
        model = create_referent
        model.referent_id = create_referent.id
        expect(model).not_to be_valid
        expect(model.errors.details[:referent_id]).to include({ error: :a_referent_cannot_have_a_referent })
      end

      it 'has error when a particular with a referent becomes a referent' do
        model = create_particular(create_referent)
        model.is_referent = true
        expect(model).not_to be_valid
        expect(model.errors.details[:referent_id]).to include({ error: :a_referent_cannot_have_a_referent })
      end

      it 'has error when a particular becomes a referent and gets a referent' do
        model = create_particular
        model.is_referent = true
        model.referent_id = create_referent.id
        expect(model).not_to be_valid
        expect(model.errors.details[:referent_id]).to include({ error: :a_referent_cannot_have_a_referent })
      end

      it 'has error when a particular gets itself as referent while becoming a referent' do
        model = create_particular
        model.is_referent = true
        model.referent_id = model.id
        expect(model).not_to be_valid
        expect(model.errors.details[:referent_id]).to include({ error: :a_referent_cannot_have_a_referent })
      end

      it 'has error when a new referent gets itself as referent' do
        model = WithReferent.new(is_referent: true)
        model.referent = model
        expect(model).not_to be_valid
        expect(model.errors.details[:referent_id]).to include({ error: :cannot_be_its_own_referent })
      end
    end

    context 'when having a referent that is not a referent' do
      it 'has error when a particular gets a particular as a referent' do
        particular = create_particular
        model = create_particular
        model.referent_id = particular.id
        expect(model).not_to be_valid
        expect(model.errors.details[:referent_id]).to(
          include({ error: :an_object_used_as_referent_must_be_flagged_as_referent })
        )
      end

      it 'has error when a referent gets itself as a referent while becoming a particular' do
        model = create_referent
        model.is_referent = false
        model.referent_id = model.id
        expect(model).not_to be_valid
        expect(model.errors.details[:referent_id]).to include({ error: :cannot_be_its_own_referent })
      end

      it 'has error when a new particular gets itself as a referent' do
        model = WithReferent.new(is_referent: false)
        model.referent = model
        expect(model).not_to be_valid
        expect(model.errors.details[:referent_id]).to(
          include({ error: :an_object_used_as_referent_must_be_flagged_as_referent })
        )
      end
    end

    context 'when being a particular and having particulars' do
      it 'has error when a referent with particulars becomes particular' do
        model = create_referent
        create_particular(model)
        model.is_referent = false
        expect(model).not_to be_valid
        expect(model.errors.details[:is_referent]).to include({ error: :the_particulars_collection_should_be_empty })
      end
    end
  end

  describe '#referents_or_self' do
    subject { WithReferent.referents_or_self }

    context 'when the model is no referent' do
      let(:model) { create_particular }

      it { is_expected.to include(model) }
    end

    context 'when the model is a Referent' do
      let(:referent) { create_referent }
      let!(:model) { create_particular(referent) }

      it { is_expected.to include(referent) }
      it { is_expected.to_not include(model) }
    end
  end

  describe '#all_referents' do
    subject { WithReferent.all_referents }

    context 'when the model is no referent' do
      let(:model) { create_particular }

      it { is_expected.to be_empty }
    end

    context 'when a model has a Referent' do
      let(:referent) { create_referent }
      let!(:model) { create_particular referent }

      it { is_expected.to contain_exactly(referent) }
    end
  end

  describe '#self_and_referents' do
    subject { WithReferent.self_and_referents }

    context 'when the model is no referent' do
      let(:model) { create_particular }

      it { is_expected.to include(model) }
    end

    context 'when a model has a Referent' do
      let(:referent) { create_referent }
      let!(:model) { create_particular referent }

      it { is_expected.to contain_exactly(model, referent) }
    end
  end
end
