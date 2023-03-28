# frozen_string_literal: true

RSpec.describe Query::Referential do
  describe '#text' do
    let(:context) do
      Chouette.create do
        workbench do
          referential :searched_referential
          referential
          referential
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:searched_referential) { context.referential(:searched_referential) }
    let(:query) { Query::Referential.new(workbench.all_referentials) }

    context 'when name is the referential name' do
      subject { query.text(searched_referential.name).scope }

      it 'includes referential' do
        is_expected.to contain_exactly(searched_referential)
      end
    end
  end

  describe '#workbenches' do
    let(:context) do
      Chouette.create do
        workbench :selected_workbench do
          referential :first
          referential :second
        end
        workbench do
          referential
          referential
        end
      end
    end

    let(:selected_workbench) { context.workbench(:selected_workbench) }
    let(:first_referential) { context.referential(:first) }
    let(:second_referential) { context.referential(:second) }
    let(:query) { Query::Referential.new(selected_workbench.all_referentials) }

    context 'when workbench is the referentials workbench' do
      subject { query.workbenches([selected_workbench]).scope }

      it 'includes 2 referentials' do
        is_expected.to contain_exactly(first_referential, second_referential)
      end
    end
  end

  describe '#line' do
    let(:context) do
      Chouette.create do
        workbench do
          line :included

          referential :searched_referential, lines: [:included]
          referential
          referential
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:searched_referential) { context.referential(:searched_referential) }
    let(:line) { context.line(:included) }
    let(:query) { Query::Referential.new(workbench.all_referentials) }

    context 'when line is the referential line' do
      subject { query.line(line.id).scope }

      it 'includes referential' do
        is_expected.to contain_exactly(searched_referential)
      end
    end
  end

  describe '#in_period' do
    let(:context) do
      Chouette.create do
        workbench do
          referential :searched_referential, periods: [Date.parse('2030-06-01')..Date.parse('2030-06-30')]
          referential
          referential
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:searched_referential) { context.referential(:searched_referential) }
    let(:line) { context.line }
    let(:metadata) { searched_referential.metadatas.first }
    let(:metadata_begin) { metadata.periods.first.begin }
    let(:metadata_end) { metadata.periods.first.end }
    let(:query) { Query::Referential.new(workbench.all_referentials) }

    context 'when period intersects with at least one period of referential' do
      let(:date_range) { metadata_begin - 10..metadata_begin + 2 }
      subject { query.in_period(date_range).scope }

      it 'includes referential' do
        is_expected.to contain_exactly(searched_referential)
      end
    end

    context 'when period never intersects with at least one period of referential' do
      let(:date_range) { metadata_begin - 10..metadata_begin - 2 }
      subject { query.in_period(date_range).scope }

      it 'should not include referential' do
        is_expected.not_to contain_exactly(searched_referential)
      end
    end
  end

  describe '#states' do
    let(:context) do
      Chouette.create do
        workbench do
          referential :archived, archived_at: Time.now
          referential :pending
          referential :failed, failed_at: Time.now
          referential :active
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:archived_referential) { context.referential(:archived) }
    let(:pending_referential) { context.referential(:pending) }
    let(:failed_referential) { context.referential(:failed) }
    let(:active_referential) { context.referential(:active) }
    let(:query) { Query::Referential.new(workbench.all_referentials) }

    #  Should update after object creation ready attribute (set to true by default)
    before(:each) do
      archived_referential.update_columns(ready: false)
      pending_referential.update_columns(ready: false)
      failed_referential.update_columns(ready: false)
    end

    Referential::STATES.each do |state|
      context "when status #{state} is the referential status" do
        subject { query.statuses([state.to_s]).scope }

        it 'includes referential' do
          is_expected.to include(send("#{state}_referential"))
        end
      end
    end
  end
end
