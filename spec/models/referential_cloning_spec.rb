
RSpec.describe ReferentialCloning, :type => :model do

  it 'should have a valid factory' do
    expect(FactoryGirl.build(:referential_cloning)).to be_valid
  end

  it { should belong_to :source_referential }
  it { should belong_to :target_referential }

  it 'should have the correct arguments in commands' do
    r = FactoryGirl.create(:referential_cloning)
    allow(r).to receive(:source_schema) { 'test_1' }
    allow(r).to receive(:database) { 'chouette_test' }

    expect(r.dump_command).to eq "PGPASSWORD='chouette' pg_dump --host localhost --port 5432 --username chouette --schema=test_1 chouette_test"
    expect(r.restore_command).to eq "PGPASSWORD='chouette' psql -q --host localhost --port 5432 --username chouette chouette_test"

    allow(r).to receive(:port) { 1234 }
    expect(r.dump_command).to eq "PGPASSWORD='chouette' pg_dump --host localhost --port 1234 --username chouette --schema=test_1 chouette_test"
    expect(r.restore_command).to eq "PGPASSWORD='chouette' psql -q --host localhost --port 1234 --username chouette chouette_test"
  end

  let(:source_referential) { Referential.new slug: "source", organisation: build(:organisation), prefix: "source"}
  let(:target_referential) { Referential.new slug: "target", organisation: source_referential.organisation, prefix: "target"}
  let(:referential_cloning) do
    ReferentialCloning.new source_referential: source_referential,
                           target_referential: target_referential
  end

  describe 'after commit' do
    let(:referential_cloning) { FactoryGirl.create(:referential_cloning) }

    it 'invokes clone method' do
      expect(referential_cloning).to receive(:clone)
      referential_cloning.run_callbacks(:commit)
    end
  end

  describe '#worker_died' do
    let(:referential_cloning) { FactoryGirl.create(:referential_cloning) }

    it 'should set merge status to failed' do
      expect(referential_cloning.status).to eq("new")
      referential_cloning.worker_died
      expect(referential_cloning.status).to eq("failed")
    end
  end

  describe '#clone' do
    let(:referential_cloning) { FactoryGirl.create(:referential_cloning) }

    it "should schedule a job in worker" do
      expect{referential_cloning}.to change { Delayed::Job.count }.by(1)
    end
  end

  describe '#clone!' do
    let(:cloner) { double }

    it 'creates a schema cloner with source and target schemas and clone schema' do
      %w{dump_command sed_command restore_command}.each do |command|
        allow(referential_cloning).to receive(command).and_return(command)
      end
      allow(referential_cloning).to receive(:clean)

      expect(referential_cloning).to receive(:system).with("dump_command | sed_command | restore_command").and_return(true)

      referential_cloning.clone!
    end
  end

  describe '#clone_with_status!' do
    it 'invokes clone! method' do
      expect(referential_cloning).to receive(:clone!)
      referential_cloning.clone_with_status!
    end

    context 'when clone_schema is performed without error' do
      it "should have successful status" do
        expect(referential_cloning).to receive(:clone!)
        referential_cloning.clone_with_status!
        expect(referential_cloning.status).to eq("successful")
      end
    end

    context 'when clone_schema raises an error' do
      it "should have failed status", truncation: true do
        expect(referential_cloning).to receive(:clone!).and_raise("#fail")
        referential_cloning.clone_with_status!
        expect(referential_cloning.status).to eq("failed")
        expect(referential_cloning.target_referential.state).to eq(:failed)
      end
    end

    it "defines started_at" do
      referential_cloning.clone_with_status!
      expect(referential_cloning.started_at).not_to be_nil
    end

    it "defines ended_at" do
      referential_cloning.clone_with_status!
      expect(referential_cloning.ended_at).not_to be_nil
    end
  end
end
