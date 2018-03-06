RSpec.describe ComplianceControlSetCloner do

  subject{ described_class.new }

  let( :new_organisation ){ create :organisation }

  let( :source_set ){ create :compliance_control_set }
  let( :set_prefix ){ I18n.t('compliance_control_sets.clone.prefix') }
  let( :block_prefix ){ I18n.t('compliance_control_blocks.clone.prefix') }


  context 'Copying empty set' do

    context 'correct organisation' do

      #
      #
      #
      #
      #
      #
      #
      #                                                 +-------------------+
      #          +---------------------+----------------| Control (direct0) |
      #          |                     |                +-------------------+
      #          |                     |
      #          |                     |                +-------------------+
      #          +---------------------)------------+---| Control (direct1) |
      #          |                     |            |   +-------------------+
      #          |                     |            |
      #          |                     |            |   +-------------------+
      #          +---------------------)------------)---| Control (direct2) |
      #          |                     |            |   +-------------------+
      #          |                     |            |
      #          |                     |            |
      #          |                     |            |
      #          v                     v            |
      #   +------------+          +--------------+  |  +---------------------+
      #   | ControlSet |<----+----| ControlBlock |<-)--| Control (indirect0) |
      #   +------------+     |    +--------------+  |  +---------------------+
      #                      |                      |
      #                      |    +--------------+<-+  +---------------------+
      #                      |<---| ControlBlock |<----| Control (indirect1) |
      #                      |    +--------------+     +---------------------+
      #                      |
      #                      |    +--------------+     +---------------------+
      #                      +----| ControlBlock |<----| Control (indirect2) |
      #                           +--------------+     +---------------------+

      context 'Directed Acyclic Graph is copied correctly' do
        let(:source_blox){
          3.times.map{ |n| create :compliance_control_block, compliance_control_set: source_set, transport_mode: StifTransportModeEnumerations.transport_modes[n], transport_submode: StifTransportSubmodeEnumerations.transport_submodes[n]   }
        }
        let(:direct_ccs){
          3.times.map{ |n| create :generic_attribute_control_min_max, compliance_control_set: source_set, name: "direct #{n.succ}", code: "direct-#{n.succ}" }
        }
        # Needed to check we do not dulicate a node (compliance_control) twice
        let(:indirect_ccs){
          # Create 1 child for each block and also associate first of the direct ccs to the first block
          #                                                  seconf of the direct css to the second block
          source_blox.take(2).zip(direct_ccs.take(2)).each do | source_block, cc |
            cc.update compliance_control_block_id: source_block.id
          end
          source_blox.each_with_index.map{ | source_block, n |
            create(:generic_attribute_control_min_max, compliance_control_set: source_set, compliance_control_block: source_block, name: "indirect #{n.succ}", code: "indirect-#{n.succ}")
          }
        }
        let( :sources ){ source_set.compliance_controls.order(:id) }

        let( :target_set ){ ComplianceControlSet.last }
        let( :target_blox ){ ComplianceControlBlock.last 3 }
        let( :targets ){ target_set.compliance_controls.order(:id) }

        before do
          direct_ccs
          indirect_ccs
        end
        it 'correctly creates a set for a complete DAG' do
          # Slowness of tests constrains us to create a minimum of objects in the DB,
          # hence only one example :(
          #
          #  Execute copy and keep count
          counts = object_counts
          subject.copy(source_set.id, new_organisation.id)
          delta  = count_diff counts, object_counts

          # Check correctly copied set
          expect(target_set.organisation).to eq(new_organisation)
          expect(target_set.name).to eq( [set_prefix, source_set.name].join(' ') )

          # Check correctly copied controls
          targets.zip(sources).each do | target, source |
            expect( target.code ).to eq(source.code )
            expect( target.comment ).to eq(source.comment )
            expect( target.compliance_control_set ).to eq( target_set )
            expect( target.control_attributes ).to eq(source.control_attributes)
            expect( target.criticity ).to eq(source.criticity )
            expect( target.name ).to eq(source.name)
            expect( target.origin_code ).to eq(source.origin_code )
            expect( target.type ).to eq(source.type)
          end
          # Check correctly copied blocks
          target_blox.zip(source_blox).each do | target_block, source_block |
            expect( target_block.compliance_control_set ).to eq(target_set)
            expect( target_block.name ).to eq(source_block.name)
            expect( target_block.condition_attributes ).to eq( source_block.condition_attributes )
          end

          # Check correct block associations
          # See diagram above to understand the meaning of this:
          #   - The first two controls have been assigned to the first two blocks accordingly
          #   - The third has no block
          #   - The last three controls have been created from the three blocks in order
          expected_block_ids = target_blox.take(2).map(&:id) + [ nil ] + target_blox.map(&:id)
          expect( targets.pluck(:compliance_control_block_id) ).to eq( expected_block_ids )

          # Check overall counts (no additional creations)
          expect( delta ).to eq(counts)
        end
      end

    end

    def object_counts
      {
        source_set_count: ComplianceControlSet.count,
        cc_block_count: ComplianceControlBlock.count,
        cc_count: ComplianceControl.count,
        cck_set_count: ComplianceCheckSet.count,
        cck_block_count: ComplianceCheckBlock.count,
        cck_count: ComplianceCheck.count
      }
    end

    def count_diff count1, count2
      count1.inject({}){ |h, (k,v)|
        h.merge( k => count2[k] - v )
      }
    end

  end

end
