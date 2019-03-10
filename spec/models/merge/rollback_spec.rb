require "rails_helper"

RSpec.describe Merge do
  let(:stop_area_referential){ create :stop_area_referential }
  let(:line_referential){ create :line_referential }
  let(:company){ create :company, line_referential: line_referential }
  let(:workbench){ create :workbench, line_referential: line_referential, stop_area_referential: stop_area_referential }
  let(:referential){
    ref = create :referential, workbench: workbench, organisation: workbench.organisation
    create(:referential_metadata, lines: line_referential.lines.limit(3), referential: ref)
    ref.reload
  }
  let(:referential_metadata){ referential.metadatas.last }

  before(:each) do
    4.times { create :line, line_referential: line_referential, company: company, network: nil }
    10.times { create :stop_area, stop_area_referential: stop_area_referential }
  end

  context "#rollback?" do
    let(:workbench){ create :workbench }
    let(:output) do
       out = workbench.output
       3.times do
         out.referentials << create(:workbench_referential, workbench: workbench, organisation: workbench.organisation)
       end
       out.current = out.referentials.last
       out.save!
       out
    end

    def create_referential
      create(:workbench_referential, organisation: workbench.organisation, workbench: workbench, metadatas: [create(:referential_metadata)])
    end

    def create_merge(attributes = {})
      attributes = {
        workbench: workbench,
        status: :successful,
        referentials: 2.times.map { create_referential.tap(&:merged!) }
      }.merge(attributes)
      create :merge, attributes
    end

    let(:previous_merge){ create_merge }
    let(:previous_failed_merge){ create_merge status: :failed }
    let(:merge){ create_merge }
    let(:final_merge){ create_merge }

    before(:each){
      previous_merge.update new: output.referentials.sort_by(&:created_at)[0]
      merge.update new: output.referentials.sort_by(&:created_at)[1]
      final_merge.update new: output.referentials.sort_by(&:created_at)[2]
    }

    context "when the current output is mine" do
      before(:each) do
        merge.new = output.current
      end

      it "should raise an error" do
        expect{merge.rollback!}.to raise_error RuntimeError
      end
    end

    context "when the current output is not mine" do
      it "should set the output current referential" do
        merge.rollback!
        expect(output.reload.current).to eq merge.new
      end

      it "should change the other merges status" do
        merge.rollback!
        expect(previous_merge.reload.status).to eq "successful"
        expect(previous_failed_merge.reload.status).to eq "failed"
        expect(final_merge.reload.status).to eq "canceled"
      end

      it "should mark other merges source referentials as not merged" do
        merge.rollback!
        previous_merge.reload.referentials.each do |r|
          expect(r.merged_at).to_not be_nil
          expect(r.archived_at).to_not be_nil
        end
        merge.reload.referentials.each do |r|
          expect(r.merged_at).to_not be_nil
          expect(r.archived_at).to_not be_nil
        end
        final_merge.reload.referentials.each do |r|
          expect(r.merged_at).to be_nil
          expect(r.archived_at).to be_nil
        end
        expect(final_merge.new.state).to eq :active
      end
    end

    context 'when another concurent referential has been created meanwhile' do
      before(:each) do
        concurent = create_referential.tap(&:active!)
        metadata = final_merge.referentials.last.metadatas.last
        concurent.update metadatas: [create(:referential_metadata, line_ids: metadata.line_ids, periodes: metadata.periodes)]
      end

      it 'should leave the referential archived' do
        merge.rollback!
        r = final_merge.referentials.last
        expect(r.merged_at).to be_nil
        expect(r.archived_at).to_not be_nil
      end
    end
  end

end
