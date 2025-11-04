# frozen_string_literal: true

RSpec.describe Chouette::ChecksumManager::Inline do
  subject(:manager) { described_class.new }

  let(:context) do
    Chouette.create do
      referential do
        route
      end
    end
  end
  let(:referential) { context.referential }
  let(:route) { context.route }

  before { referential.switch }

  context "#watch" do
    let(:object){ route }
    context "with an actual AR object" do
      it 'should update the checksum but not in DB' do
        expect(object).to receive(:set_current_checksum_source)
        expect(object).to receive(:update_checksum)
        manager.watch(object, nil)
      end
    end

    context "with an serialized object" do
      let!(:object){ [route.class.name, route.id] }

      before(:each) do
        @update_calls = Hash.new { |hash, key| hash[key] = 0 }
        allow_any_instance_of(Chouette::Route).to receive(:update_checksum_without_callbacks!).and_wrap_original do |m, *opts|
          @update_calls[m.receiver.id] += 1
          m.call(*opts)
        end
      end

      it 'should update the checksum in DB' do
        manager.watch(object, nil)
        expect(@update_calls.size).to eq(1)
        expect(@update_calls[route.id]).to eq(1)
      end
    end
  end
end
