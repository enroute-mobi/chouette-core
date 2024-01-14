# frozen_string_literal: true

RSpec.describe Chouette::Sync::Deleter do
  describe 'with real target' do
    let(:context) do
      Chouette.create do
        stop_area_provider
      end
    end

    let(:target) { context.stop_area_provider }

    subject(:deleter) do
      Chouette::Sync::Deleter.new target: target, delete_batch_size: 3,
                                  model_type: :stop_area, model_id_attribute: :registration_number
    end

    let(:useless_models) do
      [].tap do |useless_models|
        10.times do |n|
          useless_models << target.stop_areas.create!(name: "Name #{n}", registration_number: n)
        end
      end
    end

    let(:resource_identifiers) { useless_models.map(&:registration_number) }

    it 'remove useless models' do
      expect { deleter.delete(resource_identifiers) }.to change(target.stop_areas, :count).by(-useless_models.size)
    end

    it 'keeps usefull models' do
      10.times do |n|
        target.stop_areas.create name: "Usefull #{n}", registration_number: "skip #{n}"
      end

      expect { deleter.delete(resource_identifiers) }.to_not(change do
                                                               target.stop_areas.where("name like 'Usefull%'").count
                                                             end)
    end

    it 'sends events with deleted model counts' do
      delete_count = 0
      deleter.event_handler = Chouette::Sync::Event::Handler.new { |event| delete_count += event.count }
      expect { deleter.delete(resource_identifiers) }.to change { delete_count }.by(useless_models.size)
    end
  end
end
