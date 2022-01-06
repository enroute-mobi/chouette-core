RSpec.describe HoleSentinel do

  let(:context) do
    Chouette.create do
      organisation :with_user do
        user
      end

      workbench organisation: :with_user do
        referential
      end
    end
  end

  let(:referential) { context.referential }
  let(:workbench) { referential.workbench }
  let(:line) { referential.lines.first }
  let(:sentinel) { HoleSentinel.new(workbench) }

  before(:each) do
    workbench.output.update current: referential
    referential.switch
  end

  describe '#incoming_holes' do
    subject { sentinel.incoming_holes }
    context 'without stats' do
      it { should be_empty }
    end

    context 'with stats' do
      context 'with no hole' do
        before(:each) do
          1.upto(10).each do |i|
            referential.service_counts.create! date: i.day.since.to_date, count: 1, line_id: line.id
          end
        end

        it { should be_empty }
      end

      context 'with a tiny hole' do
        before(:each) do
          1.upto(3).each do |i|
            referential.service_counts.create! date: i.day.since.to_date, count: 1, line_id: line.id
          end
          4.upto(5).each do |i|
            referential.service_counts.create! date: i.day.since.to_date, count: 0, line_id: line.id
          end
          6.upto(30).each do |i|
            referential.service_counts.create! date: i.day.since.to_date, count: 1, line_id: line.id
          end
        end

        it { should be_empty }
      end

      context 'with a hole' do
        before(:each) do
          1.upto(3).each do |i|
            referential.service_counts.create! date: i.day.since.to_date, count: 1, line_id: line.id
          end
          4.upto(9).each do |i|
            referential.service_counts.create! date: i.day.since.to_date, count: 0, line_id: line.id
          end
          10.upto(30).each do |i|
            referential.service_counts.create! date: i.day.since.to_date, count: 1, line_id: line.id
          end
        end

        context "without notification rules" do
          it { should be_present }
        end

        context "with notification rules not covering all the holes" do
          before(:each) do
            workbench.notification_rules << create(:notification_rule, workbench: workbench, line_ids: [line.id], period: Time.zone.today...8.day.since.to_date)
          end

          it { should be_present }

          it 'should have a hole for the line with the date' do
            expect(subject[line.id]).to eq 4.days.since.to_date
          end
        end

        context "with notification rules covering all the holes" do
          before(:each) do
            workbench.notification_rules << create(:notification_rule, workbench: workbench, line_ids: [line.id], period: Time.zone.today...30.day.since.to_date)
          end

          it { should be_empty }
        end
      end

      context 'with a hole in the past' do
        before(:each) do
          -20.upto(-10).each do |i|
            referential.service_counts.create! date: i.day.since.to_date, count: 1, line_id: line.id
          end
          -9.upto(-3).each do |i|
            referential.service_counts.create! date: i.day.since.to_date, count: 0, line_id: line.id
          end
          -3.upto(30).each do |i|
            referential.service_counts.create! date: i.day.since.to_date, count: 1, line_id: line.id
          end
        end

        it { should be_empty }
      end
    end
  end
end
