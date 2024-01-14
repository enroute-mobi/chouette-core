# frozen_string_literal: true

RSpec.describe Chouette::Sync::Company do
  describe Chouette::Sync::Company::Netex do
    let(:context) do
      Chouette.create do
        line_provider
      end
    end

    let(:target) { context.line_provider }

    mattr_reader :created_id, default: 'FR1:Operator:025:LOC'
    mattr_reader :updated_id, default: 'FR1:Operator:251:LOC'

    let(:xml) do
      %(
        <operators>
          <Operator version="any"
          dataSourceRef="FR1:OrganisationalUnit::"
          changed="2019-04-23T13:04:39Z"
          id="#{created_id}">
            <BrandingRef ref="/uploads/logos/" />
            <Name>CEOBUS</Name>
            <ContactDetails>
              <ContactPerson></ContactPerson>
              <Email></Email>
              <Phone>01 34 42 72 74</Phone>
              <Url></Url>
              <FurtherDetails></FurtherDetails>
            </ContactDetails>
            <Address>
              <HouseNumber>35</HouseNumber>
              <AddressLine1></AddressLine1>
              <Street>rue des fossettes</Street>
              <Town>Génicourt</Town>
              <PostCode>95650</PostCode>
              <PostCodeExtension></PostCodeExtension>
            </Address>
          </Operator>
          <Operator version="any"
          dataSourceRef="FR1:OrganisationalUnit:IDFM:"
          changed="2019-09-09T09:20:30Z"
          id="#{updated_id}">
            <BrandingRef ref="/uploads/logos/" />
            <Name>TIM BUS</Name>
            <ContactDetails>
              <ContactPerson>Maddy</ContactPerson>
              <Email>contact@tim-bus.fr</Email>
              <Phone>01 34 46 88 00</Phone>
              <Url>http://tim-bus.fr</Url>
              <FurtherDetails>More</FurtherDetails>
            </ContactDetails>
            <Address>
              <HouseNumber>7</HouseNumber>
              <AddressLine1>ZA de la Demi-Lune</AddressLine1>
              <Street>rue des Frères Montgolfier</Street>
              <Town>Magny en Vexin</Town>
              <PostCode>95420</PostCode>
              <PostCodeExtension>Cedex 21</PostCodeExtension>
            </Address>
          </Operator>
        </operators>
      )
    end

    let(:source) do
      Netex::Source.new.tap do |source|
        source.include_raw_xml = true
        source.parse StringIO.new(xml)
      end
    end

    before do
      # In IBOO the line_referential should use stif_codifligne objectid_format
      if Chouette::Sync::Base.default_model_id_attribute == :objectid
        context.line_referential.update objectid_format: 'stif_codifligne'
      end
    end

    subject(:sync) do
      Chouette::Sync::Company::Netex.new source: source, target: target
    end

    let(:model_id_attribute) { Chouette::Sync::Base.default_model_id_attribute }

    let!(:updated_company) do
      target.companies.create! name: 'Old Name', model_id_attribute => updated_id
    end

    let(:created_company) do
      company(created_id)
    end

    def company(registration_number)
      target.companies.find_by(model_id_attribute => registration_number)
    end

    it "should create the Company #{created_id}" do
      sync.synchronize

      expected_attributes = {
        name: 'CEOBUS',
        time_zone: 'Europe/Paris',
        default_contact_phone: '01 34 42 72 74',
        house_number: '35',
        street: 'rue des fossettes',
        town: 'Génicourt',
        postcode: '95650'
      }
      expect(created_company).to have_attributes(expected_attributes)
    end

    it "should update the #{updated_id}" do
      sync.synchronize

      expected_attributes = {
        name: 'TIM BUS',
        time_zone: 'Europe/Paris',
        default_contact_name: 'Maddy',
        default_contact_email: 'contact@tim-bus.fr',
        default_contact_phone: '01 34 46 88 00',
        default_contact_url: 'http://tim-bus.fr',
        default_contact_more: 'More',
        house_number: '7',
        address_line_1: 'ZA de la Demi-Lune',
        street: 'rue des Frères Montgolfier',
        town: 'Magny en Vexin',
        postcode: '95420',
        postcode_extension: 'Cedex 21'
      }
      expect(updated_company.reload).to have_attributes(expected_attributes)
    end

    it 'should destroy Companies no referenced in the source' do
      useless_company =
        target.companies.create! name: 'Useless', model_id_attribute => 'unknown'
      sync.synchronize
      expect(target.companies.where(id: useless_company)).to_not exist
    end
  end
end
