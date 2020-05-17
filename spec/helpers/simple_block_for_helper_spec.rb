describe SimpleBlockForHelper, type: :helper do

  describe "#simple_block_for" do

    let(:gtfs_import) { create(:gtfs_import) }

    it "builds an empty block with title" do
      block = simple_block_for gtfs_import, title: I18n.t("simple_block_for.title.processing"), class: "col-lg-6 col-md-6 col-sm-12 col-xs-12" do |b|
      end
      expect(block).to match_snapshot "simple_block_for/empty_block"
    end

    it "builds a block with a value for an attribute" do
      block = simple_block_for gtfs_import, title: I18n.t("simple_block_for.title.processing"), class: "col-lg-6 col-md-6 col-sm-12 col-xs-12" do |b|
        b.attribute :test,  value: "Test"
      end
      expect(block).to match_snapshot "simple_block_for/attribute_with_value"
    end

    it "builds a block with a duration attribute" do
      block = simple_block_for gtfs_import, title: I18n.t("simple_block_for.title.processing"), class: "col-lg-6 col-md-6 col-sm-12 col-xs-12" do |b|
        b.attribute :duration,  as: :duration, value: 120
      end
      expect(block).to match_snapshot "simple_block_for/duration_attribute"
    end

    it "builds a block with a datetime attribute" do
      block = simple_block_for gtfs_import, title: I18n.t("simple_block_for.title.processing"), class: "col-lg-6 col-md-6 col-sm-12 col-xs-12" do |b|
        b.attribute :created_at, value: DateTime.new(2001,2,3,4,5,6) ,as: :datetime
      end
      expect(block).to match_snapshot "simple_block_for/datetime_attribute"
    end

    it "builds a block with a enumerize attribute" do
      block = simple_block_for gtfs_import, title: I18n.t("simple_block_for.title.processing"), class: "col-lg-6 col-md-6 col-sm-12 col-xs-12" do |b|
        b.attribute :notification_target, as: :enumerize
      end
      expect(block).to match_snapshot "simple_block_for/enumerize_attribute"
    end

  end

end
