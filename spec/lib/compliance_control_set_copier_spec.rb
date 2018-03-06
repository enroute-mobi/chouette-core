RSpec.describe ComplianceControlSetCopier do

  subject{ described_class.new }

  let( :cc_set ){ create :compliance_control_set }

  context 'Copying empty set' do
    context 'incorrect organisation' do
      # Assuring the organisation missmatch
      before { referential.organisation_id = cc_set.organisation_id.succ }
      it 'fails' do
        expect{ subject.copy(cc_set.id, referential.id) }.to raise_error(ArgumentError)
      end
      it 'does not create any objects in the database' do
        expect{ subject.copy(cc_set.id, referential.id) rescue nil }.to_not change{ComplianceCheckSet.count}
        expect{ subject.copy(cc_set.id, referential.id) rescue nil }.to_not change{ComplianceCheckBlock.count}
        expect{ subject.copy(cc_set.id, referential.id) rescue nil }.to_not change{ComplianceCheck.count}
      end
    end

    context 'correct organisation' do
      let(:ref){ create :referential, organisation_id: cc_set.organisation_id }

      context 'Directed Acyclic Graph is copied correctly' do
        let(:cc_blox){
          3.times.map{ |n| create :compliance_control_block, compliance_control_set: cc_set, transport_mode: StifTransportModeEnumerations.transport_modes[n], transport_submode: StifTransportSubmodeEnumerations.transport_submodes[n] }
        }
        let!(:direct_ccs){
          3.times.map{ |n| create :compliance_control, compliance_control_set: cc_set, name: "direct #{n.succ}", code: "direct-#{n.succ}" }
        }
        # Needed to check we do not dulicate a node (compliance_control) twice
        let!(:indirect_ccs){
          # Create 1 child for each block and also associate first of the direct ccs to the first block
          #                                                  seconf of the direct css to the second block
          cc_blox.take(2).zip(direct_ccs.take(2)).each do | cc_block, cc |
            cc.update compliance_control_block_id: cc_block.id
          end
          cc_blox.each_with_index.map{ | cc_block, n |
            create(:compliance_control, compliance_control_set: cc_set, compliance_control_block: cc_block, name: "indirect #{n.succ}", code: "indirect-#{n.succ}")
          }
        }

        let( :cck_set ){ ComplianceCheckSet.last }
        let( :cck_blox ){ cck_set.compliance_check_blocks }
        let( :ccks ){ cck_set.compliance_checks }

        it 'correctly creates a cck_set for a complete DAG' do
          # Slowness of tests constrains us to create a minimum of objects in the DB,
          # hence only one example :(
          counts = object_counts
          subject.copy(cc_set.id, ref.id)

          # Did not change the original objects
          # Correct numbers
          expect( ComplianceControlSet.count ).to eq(counts.cc_set_count)
          expect( ComplianceControlBlock.count ).to eq(counts.cc_block_count)
          expect( ComplianceControl.count ).to eq(counts.cc_count)

          expect( ComplianceCheckSet.count ).to eq(counts.cck_set_count + 1)
          expect( cck_blox.count ).to eq(counts.cck_block_count + cc_blox.size)
          expect( ccks.count ).to eq(counts.cck_count + direct_ccs.size + indirect_ccs.size)

          # Correcly associated
          expect( cck_blox.map(&:compliance_checks).map(&:size) )
            .to eq([2, 2, 1])
          expect( ComplianceCheck.where(name: mk_name('direct 1')).first.compliance_check_block_id )
            .to eq( cck_blox.first.id )
          expect( ComplianceCheck.where(name: mk_name('direct 3')).first.compliance_check_block_id ).to be_nil
        end
      end

      context 'Node data is copied correctly' do
        let( :cc_block ){ create :compliance_control_block, compliance_control_set: cc_set }

        let!( :control ){ create :compliance_control,
                          compliance_control_set: cc_set,
                          compliance_control_block: cc_block,
                          name: 'control' }

        let( :cck_set )    { ComplianceCheckSet.last }
        let( :cck_block )  { ComplianceCheckBlock.last }
        let( :cck )        { ComplianceCheck.last }

        it 'into the compliance_check nodes' do
          subject.copy(cc_set.id, ref.id)

          # Set
          expect( cck_set.name ).to eq(mk_name(cc_set.name))

          # Block
          expect( cck_block.name ).to eq(mk_name(cc_block.name))
          expect( cck_block.condition_attributes ).to eq(cc_block.condition_attributes)

          # Control/Check
          att_names = %w{  control_attributes code criticity comment origin_code }
          expected  = control.attributes.values_at(*att_names) << mk_name(control.name)
          actual    = cck.attributes.values_at(*(att_names << 'name'))

          expect( actual ).to eq( expected )

        end

        it 'returns the newly-created ComplianceCheckSet' do
          expect(subject.copy(cc_set.id, ref.id)).to eq(cck_set)
        end
      end

    end


    def object_counts
      OpenStruct.new \
        cc_set_count: ComplianceControlSet.count,
        cc_block_count: ComplianceControlBlock.count,
        cc_count: ComplianceControl.count,
        cck_set_count: ComplianceCheckSet.count,
        cck_block_count: ComplianceCheckBlock.count,
        cck_count: ComplianceCheck.count
    end

    def mk_name name
      [name, ref.name].join('-')
    end
  end

end
