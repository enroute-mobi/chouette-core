# frozen_string_literal: true

RSpec.describe Import::Netex do
  describe '#line_ids' do
    let(:context) do
      Chouette.create do
        workbench do
          line :line1, objectid: 'FR1:Line:1:'
          line :line2, objectid: 'FR1:Line:2:'
          line :line3, objectid: 'FR1:Line:3:'
        end
        code_space
      end
    end
    let(:workbench) { context.workbench }

    let(:file_path) do
      lines = Tempfile.new
      file = Tempfile.new(['import_netex', '.zip'])
      Zip::File.open(file.path, create: true) do |zip|
        zip.mkdir('OFFRE_20231227155226')
        zip.add('OFFRE_20231227155226/calendriers.xml',
                fixtures_path('netex-calendar-files/single_period_calendar.xml'))
        zip.add('OFFRE_20231227155226/offre_1_1.xml', lines.path)
        zip.add('OFFRE_20231227155226/offre_2_2.xml', lines.path)
        zip.add('OFFRE_20231227155226/offre_4_4.xml', lines.path)
      end
      file.path
    end
    let(:import) { Import::Netex.new(workbench: workbench, file: File.open(file_path)) }

    it 'returns only line ids of worbench lines present in the file' do
      expect(import.line_ids).to match_array([context.line(:line1).id, context.line(:line2).id])
    end
  end
end
