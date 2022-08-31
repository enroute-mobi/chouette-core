RSpec.describe Macro::DefineAttributeDefaultValue::Run do

  let(:macro_list_run) do
    Macro::List::Run.create workbench: context.workbench
  end
  let(:macro_run) do
		described_class.create(
			macro_list_run: macro_list_run,
			position: 0,
			options: { target_model: target_model, model_attribute_name: model_attribute_name }
		)
	end

  let(:context) do
    Chouette.create { workbench }
  end

  describe "#run" do
		let(:referent) { context.stop_area(:referent) }
		let(:target_model) { 'StopArea' }
		let(:model_attribute_name) { 'time_zone' }

    before(:each) { macro_run.run }

		context 'when referent attribute is undefined and one particular have defined value' do
			let(:context) do
				Chouette.create do
					stop_area :referent, is_referent: true, time_zone: nil
					stop_area time_zone: 'Europe/Paris', referent: :referent
				end
			end

			it 'should update referent attribute with particular value' do
				expect(referent.reload.time_zone).to eq('Europe/Paris')
			end
		end

		context 'when referent attribute is undefined and all particulars have the same defined value' do
			let(:context) do
				Chouette.create do
					stop_area :referent, is_referent: true, time_zone: nil
					stop_area time_zone: 'Europe/Paris', referent: :referent
					stop_area time_zone: 'Europe/Paris', referent: :referent
				end
			end

			it 'should update referent attribute with particulars value' do
				expect(referent.reload.time_zone).to eq('Europe/Paris')
			end
		end

		context 'when referent attribute is undefined and particulars have different defined value' do
			let(:context) do
				Chouette.create do
					stop_area :referent, is_referent: true, time_zone: nil
					stop_area time_zone: 'Europe/Paris', referent: :referent
					stop_area time_zone: 'Europe/London', referent: :referent
				end
			end

			it 'should not update referent attribute' do
				expect(referent.reload.time_zone).to be_nil
			end
		end

		context 'when referent attribute is already defined' do
			let(:context) do
				Chouette.create do
					stop_area :referent, is_referent: true, time_zone: 'Europe/Paris'
					stop_area time_zone: 'Europe/London', referent: :referent
				end
			end

			it 'should not update referent attribute' do
				expect(referent.reload.time_zone).to eq('Europe/Paris')
			end
		end
  end

  describe "#particulars" do
		let(:target_model) { 'StopArea' }
		let(:model_attribute_name) { 'time_zone' }

    subject { macro_run.particulars }

    let(:context) do
      Chouette.create do
        stop_area :referent, is_referent: true
        stop_area :particular, referent: :referent
        stop_area
      end
    end

		let(:stop_area) { context.stop_area(:particular) }

		it { is_expected.to contain_exactly(stop_area) }
  end

  describe "#referents" do
		let(:target_model) { 'StopArea' }
		let(:model_attribute_name) { 'time_zone' }

    subject { macro_run.referents }

    let(:context) do
      Chouette.create do
        stop_area :referent1, is_referent: true
				stop_area :referent2, is_referent: true
        stop_area :particular, referent: :referent
      end
    end

		it { is_expected.to contain_exactly(context.stop_area(:referent1), context.stop_area(:referent2)) }
	end
end
