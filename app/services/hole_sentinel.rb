class HoleSentinel
  extend ActiveModel::Naming

  attr_reader :workbench

  def initialize(workbench)
    @workbench = workbench
  end

  alias workbench_for_notifications workbench

  def incoming_holes
    holes = {}

    return holes unless referential.present?
    return holes unless days_ahead.positive?

    referential.switch do

      referential.lines.each do |line|
        line_holes = Stat::JourneyPatternCoursesByDate.where('date >= CURRENT_DATE').holes_for_line(line)

        # first we check that the next hole is soon enough for us to care about
        next unless line_holes.exists?
        next unless line_holes.first.date <= days_ahead.since

        # then we check that we have N consecutive 'no circulation' days
        next unless line_holes.offset(min_hole_size).first&.date == line_holes.first.date + min_hole_size

        blocked_for_everyone = !workbench.notification_center.has_recipients?(
            :hole_sentinel,
            base_recipients: base_recipients,
            line_ids: [line.id],
            period: line_holes.first.date..line_holes.last.date,
        )

        # then we check if there is any notification rule covering the hole
        next if blocked_for_everyone

        holes[line.id] = line_holes.first.date
      end
    end
    holes
  end

  def base_recipients
    @base_recipients ||= workbench.organisation.users.pluck(:email)
  end

  def watch!
    holes = incoming_holes
    return unless holes.present?

    workbench.notification_center.recipients(:hole_sentinel, line_ids: holes.keys, base_recipients: base_recipients).each do |recipient|
      Rails.logger.info "Notify #{recipient} for Hole Sentinel on Workbench##{workbench.id}"
      SentinelMailer.notify_incoming_holes(recipient, referential).deliver_now
    end
  end

  protected

  def referential
    @workbench.output.current
  end

  def min_hole_size
    @workbench.workgroup.sentinel_min_hole_size
  end

  def days_ahead
    @workbench.workgroup.sentinel_delay.days
  end
end
