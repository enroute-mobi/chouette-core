# frozen_string_literal: true

module Chouette
  class LineNoticeMembership < Chouette::ActiveRecord
    self.table_name = 'line_notices_lines'

    class << self
      def ransackable_scopes(_ = nil)
        [:title_or_content_cont]
      end
    end

    belongs_to :line, required: true, inverse_of: :line_notice_memberships
    belongs_to :line_notice, required: true, inverse_of: :line_notice_memberships

    validates :line_notice_id, uniqueness: { scope: %i[line_id] }

    scope :title_or_content_cont, lambda { |text|
      line_notices = Chouette::LineNotice.arel_table
      match = "%#{Ransack::Constants.escape_wildcards(text)}%"
      joins(:line_notice).where(line_notices['title'].matches(match).or(line_notices['content'].matches(match)))
    }
  end
end
