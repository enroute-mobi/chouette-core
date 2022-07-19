RSpec.describe Query::ProcessingRule do
	let(:query) { Query::ProcessingRule.new(ProcessingRule.all) }
	let(:sql) { query.scope.to_sql }

	describe '#worbench_rules' do
		it 'should perform right SQL query' do
			query.workbench_rules

			expect(sql).to eq("SELECT \"processing_rules\".* FROM \"processing_rules\" WHERE \"processing_rules\".\"workgroup_rule\" = FALSE")
		end
	end

	describe '#workgroup_rules' do
			it 'should perform right SQL query' do
				query.workgroup_rules

				expect(sql).to eq("SELECT \"processing_rules\".* FROM \"processing_rules\" WHERE \"processing_rules\".\"workgroup_rule\" = TRUE")
			end
	end

	describe '#target_workbenches' do
		it 'should perform right SQL query' do
			workbench = instance_double('Workbench', id: 1)
		
			query.target_workbenches(workbench)

			expect(sql).to eq("SELECT \"processing_rules\".* FROM \"processing_rules\" WHERE (ARRAY_LENGTH(target_workbench_ids, 1) = 0 OR ARRAY_LENGTH(target_workbench_ids, 1) IS NULL OR target_workbench_ids::integer[] @> ARRAY[1]::integer[])")
		end
	end

	describe '#macros' do
		it 'should perform right SQL query' do
			query.macros

			expect(sql).to eq("SELECT \"processing_rules\".* FROM \"processing_rules\" WHERE \"processing_rules\".\"processable_type\" = 'Macro::List'")
		end
	end

	describe '#controls' do
		it 'should perform right SQL query' do
			query.controls

			expect(sql).to eq("SELECT \"processing_rules\".* FROM \"processing_rules\" WHERE \"processing_rules\".\"processable_type\" = 'Control::List'")
		end
	end

	describe '#for_workgroup' do
		it 'should perform right SQL query' do
			workgroup = instance_double('Workgroup', workbench_ids: [1,2,3])

			query.for_workgroup workgroup

			expect(sql).to eq  "SELECT \"processing_rules\".* FROM \"processing_rules\" WHERE \"processing_rules\".\"workbench_id\" IN (1, 2, 3)"
		end
	end

	describe '#for_workbench' do

		describe 'when worbench is owner' do
			it 'should perform right SQL query' do
				workgroup = instance_double('Workgroup', workbench_ids: [1,2,3])
				workbench = Workbench.new

				allow(workbench).to receive(:owner?) { true }
				allow(workbench).to receive(:workgroup) { workgroup }

				query.for_workbench workbench

				expect(sql).to eq("SELECT \"processing_rules\".* FROM \"processing_rules\" WHERE \"processing_rules\".\"workbench_id\" IN (1, 2, 3)")
			end
		end

		describe 'when worbench is not owner' do
			it 'should perform right SQL query' do
				workgroup = instance_double('Workgroup', workbench_ids: [1,2,3])
				workbench = Workbench.new

				allow(workbench).to receive(:owner?) { false }
				allow(workbench).to receive(:workgroup) { workgroup }

				query.for_workbench workbench

				expect(sql).to eq("SELECT \"processing_rules\".* FROM \"processing_rules\" WHERE (\"processing_rules\".\"workbench_id\" IS NULL AND \"processing_rules\".\"workgroup_rule\" = FALSE OR \"processing_rules\".\"workbench_id\" IN (1, 2, 3) AND \"processing_rules\".\"workgroup_rule\" = TRUE AND (ARRAY_LENGTH(target_workbench_ids, 1) = 0 OR ARRAY_LENGTH(target_workbench_ids, 1) IS NULL OR target_workbench_ids::integer[] @> ARRAY[]::integer[]))")
			end
		end
	end
end
