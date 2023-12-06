RSpec.describe ReferentialOverview do

  subject{ described_class }

end

RSpec.describe ReferentialOverview::Week do

  describe "#initialize" do
    it "should respect the boundary" do
      week = ReferentialOverview::Week.new(Time.now.beginning_of_week, 1.week.from_now)
      expect(week.start_date).to eq Time.now.beginning_of_week.to_date
      expect(week.end_date).to eq Time.now.end_of_week.to_date

      week = ReferentialOverview::Week.new(Time.now.beginning_of_week, Time.now)
      expect(week.start_date).to eq Time.now.beginning_of_week.to_date
      expect(week.end_date).to eq Time.now.to_date
    end
  end
end

RSpec.describe ReferentialOverview::Line do

  let(:ref_line){create(:line)}
  let(:referential){create(:referential)}
  let(:start){2.days.ago}
  let(:period_1){(10.days.ago..8.days.ago)}
  let(:period_2){(5.days.ago..1.days.ago)}

  subject(:line){ReferentialOverview::Line.new ref_line, referential, start}

  before(:each) do
    create(:referential_metadata, referential: referential, line_ids: [ref_line.id], periodes: [period_1, period_2].compact)
  end

  describe "#width" do
    it "should have the right value" do
      expect(line.width).to eq ReferentialOverview::Day::WIDTH * referential.metadatas_period.count
    end
  end

  describe "#periods" do
    context "when the periodes are split into several metadatas" do
      let(:period_2){nil}
      before do
        create(:referential_metadata, referential: referential, line_ids: [ref_line.id], periodes: [(17.days.ago..11.days.ago)])
      end
      it "should find them all" do
        expect(line.periods.count).to eq 2
        expect(line.periods[0].filled?).to be_falsy
        expect(line.periods[1].filled?).to be_falsy
      end

      context "when the periodes overlap" do
        let(:period_2){nil}
        before do
          create(:referential_metadata, referential: referential, line_ids: [ref_line.id], periodes: [(17.days.ago..9.days.ago)])
        end
        it "should merge them" do
          expect(line.periods.count).to eq 1
          expect(line.periods[0].filled?).to be_falsy
          expect(line.periods[0].start).to eq 17.days.ago.to_date
          expect(line.periods[0].end).to eq 8.days.ago.to_date
        end
      end
    end
  end

  describe "#fill_periods" do
    it "should fill the voids" do
      expect(line.periods.count).to eq 3
      expect(line.periods[0].filled?).to be_falsy
      expect(line.periods[1].filled?).to be_falsy
      expect(line.periods[2].filled?).to be_falsy
    end

    context "with no void" do
      let(:period_1){(10.days.ago..8.days.ago)}
      let(:period_2){(7.days.ago..1.days.ago)}

      it "should find no void" do
        expect(line.periods.count).to eq 2
        expect(line.periods[0].filled?).to be_falsy
        expect(line.periods[1].filled?).to be_falsy
      end
    end

    context "with a large void" do
      let(:period_1){(20.days.ago..19.days.ago)}
      let(:period_2){(2.days.ago..1.days.ago)}

      it "should fill the void" do
        expect(line.periods.count).to eq 3
        expect(line.periods[0].filled?).to be_falsy
        expect(line.periods[1].filled?).to be_falsy
        expect(line.periods[2].filled?).to be_falsy
      end
    end

    context "with a void at the end" do
      before do
        create(:referential_metadata, referential: referential,  periodes: [(2.days.ago..1.days.ago)])
      end
      let(:period_1){(20.days.ago..19.days.ago)}
      let(:period_2){nil}

      it "should fill the void" do
        expect(line.periods.count).to eq 2
        expect(line.periods[0].filled?).to be_falsy
        expect(line.periods[1].filled?).to be_falsy
        expect(line.periods[1].end).to eq 1.days.ago.to_date
      end
    end

    context "with a void at the beginning" do
      before do
        create(:referential_metadata, referential: referential,  periodes: [(200.days.ago..199.days.ago)])
      end
      let(:period_1){(20.days.ago..19.days.ago)}
      let(:period_2){nil}

      it "should fill the void" do
        expect(line.periods.count).to eq 2
        expect(line.periods[0].start).to eq 200.days.ago.to_date
        expect(line.periods[0].filled?).to be_falsy
        expect(line.periods[1].filled?).to be_falsy
      end
    end
  end
end

RSpec.describe ReferentialOverview::Line::Period do

  let(:period){(1.day.ago.to_date..Time.now.to_date)}
  let(:start){2.days.ago.to_date}

  subject(:line_period){ReferentialOverview::Line::Period.new period, start}

  describe "#width" do
    it "should have the right value" do
      expect(line_period.width).to eq ReferentialOverview::Day::WIDTH * period.count
    end
  end

  describe "#left" do
    it "should have the right value" do
      expect(line_period.left).to eq ReferentialOverview::Day::WIDTH * 1
    end
  end
end
