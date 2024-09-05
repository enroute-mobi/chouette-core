# frozen_string_literal: true

RSpec.describe Chouette::Sync::Line do
  describe Chouette::Sync::Line::Netex do
    let(:context) do
      Chouette.create do
        line_provider
      end
    end

    let(:target) { context.line_provider }

    let(:xml) do
      %(
       <lines>
         <Line version="any"
         dataSourceRef="FR1:OrganisationalUnit: :"
         created="2015-12-04T17:18:34Z"
         changed="2019-06-25T22:00:02Z" status="inactive"
         id="FR1:Line:C01931:">
           <ValidBetween>
             <FromDate>2015-12-04T00:00:00</FromDate>
             <ToDate>2019-02-01T00:00:00</ToDate>
           </ValidBetween>
           <Name>Ligne 3 : Boucle de Chevry</Name>
           <ShortName>Ligne 3 : Boucle de Chevry</ShortName>
           <TransportMode>bus</TransportMode>
           <TransportSubmode>
             <BusSubmode>demandAndResponseBus</BusSubmode>
           </TransportSubmode>
           <PublicCode></PublicCode>
           <PrivateCode>210677013</PrivateCode>
           <OperatorRef version="any"
           ref="FR1:Operator:210:LOC" />
           <additionalOperators>
             <OperatorRef version="any"
             ref="FR1:Operator:210:LOC" />
           </additionalOperators>
           <RepresentedByGroupRef version="any"
             ref="FR1:Network:68:LOC" />
           <Presentation>
             <Colour>aaaaaa</Colour>
             <ColourName>RGB:170 170 170</ColourName>
             <TextColour>000000</TextColour>
           </Presentation>
           <AlternativePresentation>
             <ColourName>CMYK:0 0 0 33</ColourName>
             <TextColour>000000</TextColour>
           </AlternativePresentation>
           <AccessibilityAssessment id="FR1:AccessibilityAssessment:C01931:"
           version="any">
             <MobilityImpairedAccess>false</MobilityImpairedAccess>
             <limitations>
               <AccessibilityLimitation>
                 <WheelchairAccess>unknown</WheelchairAccess>
                 <AudibleSignalsAvailable>unknown</AudibleSignalsAvailable>
                 <VisualSignsAvailable>unknown</VisualSignsAvailable>
               </AccessibilityLimitation>
             </limitations>
           </AccessibilityAssessment>
           <noticeAssignments>
             <NoticeAssignment id="FR1:NoticeAssignment:C01931:"
             version="any" order="0">
               <NoticeRef version="any"
               ref="FR1:Notice:C01931:" />
             </NoticeAssignment>
           </noticeAssignments>
         </Line>
         <Line version="any"
         dataSourceRef="FR1:OrganisationalUnit: :"
         created="2014-07-16T00:00:00Z"
         changed="2019-03-06T13:28:47Z" status="active"
         id="FR1:Line:C01659:">
           <ValidBetween>
             <FromDate>2014-07-16T00:00:00</FromDate>
           </ValidBetween>
           <Name>AB</Name>
           <ShortName>A</ShortName>
           <TransportMode>bus</TransportMode>
           <TransportSubmode>
             <BusSubmode>regionalBus</BusSubmode>
           </TransportSubmode>
           <PublicCode></PublicCode>
           <PrivateCode>046146069</PrivateCode>
           <OperatorRef version="any"
           ref="FR1:Operator:046:LOC" />
           <additionalOperators>
             <OperatorRef version="any"
             ref="FR1:Operator:046:LOC" />
           </additionalOperators>
           <Presentation>
             <Colour>ff4dff</Colour>
             <ColourName>RGB:25577255</ColourName>
             <TextColour>000000</TextColour>
           </Presentation>
           <AlternativePresentation>
             <ColourName>CMYK:0 7000 0 0</ColourName>
             <TextColour>000000</TextColour>
           </AlternativePresentation>
           <AccessibilityAssessment id="FR1:AccessibilityAssessment:C01659:"
           version="any">
             <MobilityImpairedAccess>false</MobilityImpairedAccess>
             <limitations>
               <AccessibilityLimitation>
                 <WheelchairAccess>unknown</WheelchairAccess>
                 <AudibleSignalsAvailable>unknown</AudibleSignalsAvailable>
                 <VisualSignsAvailable>unknown</VisualSignsAvailable>
               </AccessibilityLimitation>
             </limitations>
           </AccessibilityAssessment>
           <noticeAssignments>
             <NoticeAssignment id="FR1:NoticeAssignment:C01659:" version="any" order="0">
               <NoticeRef version="any" ref="FR1:Notice:C01659:" />
             </NoticeAssignment>
             <NoticeAssignmentView id="FR1:NoticeAssignmentView:C01659:"
             order="0">
               <Mark>Horaires Ligne A</Mark>
               <MarkUrl>
               https://www.keolis-valdoise.com/fileadmin/Sites/keolis_val_d_oise/documents/lignes/Horaires_2019/Horaires_bus_A_Bruyeres_sur_Oise_-_Persan_2019_V2.pdf</MarkUrl>
               <TypeOfNoticeRef ref="PDFTimetable" />
             </NoticeAssignmentView>
             <NoticeAssignmentView id="FR1:NoticeAssignmentView:C01659:"
             order="1">
               <Mark>Horaire Ligne A</Mark>
               <MarkUrl>
               https://www.keolis-valdoise.com/fileadmin/Sites/keolis_val_d_oise/documents/lignes/Horaires_2019/Horaires_bus_A_Persan-_Bruyeres_sur_Oise_2019_V2.pdf</MarkUrl>
               <TypeOfNoticeRef ref="PDFTimetable" />
             </NoticeAssignmentView>
           </noticeAssignments>
         </Line>
       </lines>)
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
      Chouette::Sync::Line::Netex.new source: source, target: target
    end

    let(:model_id_attribute) { Chouette::Sync::Base.default_model_id_attribute }

    let(:created_line) do
      line('FR1:Line:C01931:')
    end

    def line(registration_number)
      target.lines.find_by(model_id_attribute => registration_number)
    end

    it 'should create the Line FR1:Line:C01931:' do
      company =
        target.companies.create! name: 'Test', model_id_attribute => 'FR1:Operator:210:LOC'
      network =
        target.networks.create! name: 'Test', model_id_attribute => 'FR1:Network:68:LOC'
      line_notice =
        target.line_notices.create! name: 'Test', model_id_attribute => 'FR1:Notice:C01931:'

      sync.synchronize

      expected_attributes = {
        name: 'Ligne 3 : Boucle de Chevry',
        number: 'Ligne 3 : Boucle de Chevry',
        transport_mode: 'bus',
        transport_submode: 'demandAndResponseBus',
        color: 'AAAAAA',
        text_color: '000000',
        company: company,
        secondary_company_ids: nil,
        line_notice_ids: [line_notice.id],
        network: network,
        desactivated: true
      }
      expect(created_line).to have_attributes(expected_attributes)
    end

    it 'should update the FR1:Line:C01659:' do
      existing_line = target.lines.create! name: 'Old Name', model_id_attribute => 'FR1:Line:C01659:'

      sync.synchronize

      expected_attributes = {
        name: 'AB',
        desactivated: false
      }
      expect(existing_line.reload).to have_attributes(expected_attributes)
    end

    it 'should destroy Lines no referenced in the source' do
      useless_line =
        target.lines.create! name: 'Useless', model_id_attribute => 'unknown'
      sync.synchronize
      expect(useless_line.reload).to be_deactivated
    end

    describe Chouette::Sync::Line::Netex::Decorator do
      subject(:decorator) { described_class.new(line) }
      let(:line) { Netex::Line.new }

      describe '#line_transport_mode' do
        subject { decorator.line_transport_mode }

        context 'when Line transport mode is "bus"' do
          before { line.transport_mode = 'bus' }
          it { is_expected.to eq('bus') }
        end

        context 'when Line transport mode is "cableway"' do
          before { line.transport_mode = 'cableway' }
          it { is_expected.to eq('telecabin') }
        end
      end
    end
  end
end
