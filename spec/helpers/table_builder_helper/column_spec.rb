require 'spec_helper'

describe TableBuilderHelper::Column do
  describe "#header_label" do
    it "returns the column @name if present" do
      expect(
        TableBuilderHelper::Column.new(
          name: 'ID Codif',
          attribute: nil
        ).header_label
      ).to eq('ID Codif')
    end

    it "returns the I18n translation of @key if @name not present" do
      expect(
        TableBuilderHelper::Column.new(
          key: :default_contact_phone,
          attribute: 'default_contact_phone'
        ).header_label(Chouette::Company)
      ).to eq('Numéro de téléphone')
    end
  end

  describe "#linkable?" do
    it "returns true if :link_to is not nil" do
      expect(
        TableBuilderHelper::Column.new(
          name: 'unused',
          attribute: nil,
          link_to: lambda do
            train.kind
          end
        ).linkable?
      ).to be true
    end

    it "returns false if :link_to is nil" do
      expect(
        TableBuilderHelper::Column.new(
          name: 'unused',
          attribute: nil
        ).linkable?
      ).to be false
    end
  end

  describe "#link_to" do
    it "calls the block passed in and returns the result" do
      train = double('train', kind: 'TGV')

      expect(
        TableBuilderHelper::Column.new(
          name: 'unused',
          attribute: nil,
          link_to: lambda do |train|
            train.kind
          end
        ).link_to(train)
      ).to eq('TGV')
    end
  end
end
