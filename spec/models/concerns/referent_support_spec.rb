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

  describe '#referents_or_self' do
    subject { WithReferent.referents_or_self }

    context 'when the model is no referent' do
      let(:model) { WithReferent.create! }

      it { is_expected.to include(model) }
    end

    context 'when the model is a Referent' do
      let(:referent) { WithReferent.create! is_referent: true }
      let!(:model) { WithReferent.create! referent: referent }

      it { is_expected.to include(referent) }
      it { is_expected.to_not include(model) }
    end
  end
end
