# frozen_string_literal: true

module Chouette
  class LineNoticeMembership < Chouette::ActiveRecord
    self.table_name = 'line_notices_lines'

    belongs_to :line, inverse_of: :line_notice_memberships # CHOUETTE-3247 required: true
    belongs_to :line_notice, inverse_of: :line_notice_memberships # CHOUETTE-3247 required: true

    validates :line_notice_id, uniqueness: { scope: %i[line_id] }
  end
end
