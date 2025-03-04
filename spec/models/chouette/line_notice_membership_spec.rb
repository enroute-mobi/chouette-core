# frozen_string_literal: true

describe Chouette::LineNoticeMembership, type: :model do
  it { is_expected.to belong_to(:line).required }
  it { is_expected.to belong_to(:line_notice).required }

  describe 'validations' do
    describe 'uniqueness' do
      let(:context) do
        Chouette.create do
          workbench do
            line :line
            line_notice lines: %i[line]
          end
        end
      end
      let(:line) { context.line(:line) }
      let(:line_notice) { context.line_notice }

      subject(:line_notice_membership) { described_class.new(line: line, line_notice: line_notice) }

      it { is_expected.not_to allow_value(line_notice.id).for(:line_notice_id) }
    end
  end
end
