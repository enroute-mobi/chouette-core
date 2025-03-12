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
