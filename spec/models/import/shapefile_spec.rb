RSpec.describe Import::Shapefile do

  let(:context) do
    Chouette.create do
      shape :first
      shape :second
      shape :third
    end
  end

  let(:workbench) { context.workbench }
  let(:filename) { 'shapefile.zip' }
  let(:file) { File.open(Rails.root.join('spec', 'fixtures', 'imports', 'shapefile', filename)) }

  let(:parent) { Import::Workbench.create workbench: workbench, file: file, creator: "test", name: "test", import_category: 'shape_file', shape_attribute_as_id: 'id_chainag' }
  let(:import) { parent.reload.children.first}
  before(:each) do
    allow(import).to receive(:local_file).and_return(file)
  end

  context "when the file is not directly accessible" do
    before(:each) do
      allow(import).to receive(:file).and_return(nil)
    end

    it "should still be able to update the import" do
      import.update status: :failed
      expect(import.reload.status).to eq "failed"
    end
  end

  describe '#force_failure!' do
    it 'should also fail the parent import' do
      import.force_failure!
      expect(parent.reload.status).to eq 'failed'
      expect(import.reload.status).to eq 'failed'
    end
  end

  context "with incorrect shapefile" do
    let(:filename) { 'incorrect_shapefile.zip' }
    it 'should fail gracefully and log an error to the user' do
      expect{ import.import }.to not_raise_error
      .and not_change{Shape.count}
      expect(import.status).to eq :failed
      expect(import.main_resource.status).to eq 'ERROR'
      expect(import.main_resource.messages.first.message_key).to eq 'shapefile_geometry_parsing_error'
    end
  end

  context "with correct shapefile" do

    let(:code_space) { import.code_space }
    let(:another_code_space) { create :code_space, workgroup: context.workgroup}
    let(:file_shapes_number) { import.source.num_records}


    it 'should import successfully' do
      import.import
      expect(import.status).to eq :successful
    end

    describe "without any shapes in the target codespace" do
      before do
        context.shape(:first).codes.create! code_space: another_code_space, value: '12_A_29'
        context.shape(:second).codes.create! code_space: another_code_space, value: '12_R_30'
        context.shape(:third).codes.create! code_space: another_code_space, value: '12_R_31'
      end

      it 'should only update shapes already existing in the target codespace' do
        expect{ import.import }.to change{Shape.count}.by(file_shapes_number)
      end
    end

    describe "with shapes already existing in the target codespace" do
      before do
        context.shape(:first).codes.create! code_space: code_space, value: '12_A_29'
        context.shape(:second).codes.create! code_space: code_space, value: '12_R_30'
        context.shape(:third).codes.create! code_space: code_space, value: '12_R_31'
      end

      it 'should only update shapes already existing in the target codespace' do
        already_existing_shapes = code_space.codes.count
        expect{ import.import }.to change{Shape.count}.by(file_shapes_number-already_existing_shapes)
      end

    end
  end

end
