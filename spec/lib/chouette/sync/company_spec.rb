RSpec.describe Chouette::Sync::Company do

  describe Chouette::Sync::Company::Netex do

    let(:context) do
      Chouette.create do
        line_referential
      end
    end

    let(:target) { context.line_referential }

    let(:xml) do
      %{
        <operators>
          <Operator version="any"
          dataSourceRef="FR1:OrganisationalUnit::"
          id="FR1:Operator:503:LOC">
            <BrandingRef ref="" />
            <Name>AEROPORT PARIS BEAUVAIS</Name>
            <ContactDetails>
              <ContactPerson></ContactPerson>
              <Email></Email>
              <Phone></Phone>
              <Url></Url>
              <FurtherDetails></FurtherDetails>
            </ContactDetails>
            <Address>
              <HouseNumber></HouseNumber>
              <AddressLine1></AddressLine1>
              <Street></Street>
              <Town></Town>
              <PostCode></PostCode>
              <PostCodeExtension></PostCodeExtension>
            </Address>
          </Operator>
          <Operator version="any"
          dataSourceRef="FR1:OrganisationalUnit::"
          id="FR1:Operator:088:LOC">
            <BrandingRef ref="" />
            <Name>VEXIN BUS</Name>
            <ContactDetails>
              <ContactPerson></ContactPerson>
              <Email></Email>
              <Phone></Phone>
              <Url></Url>
              <FurtherDetails></FurtherDetails>
            </ContactDetails>
            <Address>
              <HouseNumber></HouseNumber>
              <AddressLine1></AddressLine1>
              <Street></Street>
              <Town></Town>
              <PostCode></PostCode>
              <PostCodeExtension></PostCodeExtension>
            </Address>
          </Operator>
        </operators>
      }
    end

    let(:source) do
      Netex::Source.new.tap do |source|
        source.include_raw_xml = true
        source.parse StringIO.new(xml)
      end
    end

    subject(:sync) do
      Chouette::Sync::Company::Netex.new source: source, target: target
    end

    let!(:existing_company) do
      target.companies.create! name: "Old Name", registration_number: "FR1:Operator:503:LOC"
    end

    let(:created_company) do
      company("FR1:Operator:088:LOC")
    end

    def company(registration_number)
      target.companies.find_by(registration_number: registration_number)
    end

    it "should create the Company FR1:Operator:088:LOC" do
      sync.synchronize

      expected_attributes = {
        name: "VEXIN BUS",
        time_zone: "Europe/Paris"
      }
      expect(created_company).to have_attributes(expected_attributes)
    end

    it "should update the FR1:Company:C01659:" do
      sync.synchronize

      expected_attributes = {
        name: "AEROPORT PARIS BEAUVAIS",
      }
      expect(existing_company.reload).to have_attributes(expected_attributes)
    end

    it "should destroy Companies no referenced in the source" do
      useless_company =
        target.companies.create! name: "Useless", registration_number: "unknown"
      sync.synchronize
      expect(target.companies.where(id:useless_company)).to_not exist
    end

  end

end
