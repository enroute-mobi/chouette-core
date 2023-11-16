# frozen_string_literal: true

class ServiceCount < ActiveRecord::Base
  belongs_to :journey_pattern, class_name: 'Chouette::JourneyPattern'
  belongs_to :route, class_name: 'Chouette::Route'
  belongs_to :line, class_name: 'Chouette::Line'

  scope :for_journey_pattern, ->(journey_pattern) { where(journey_pattern_id: journey_pattern.id) }
  scope :for_line, ->(line) { where(line_id: line.id) }
  scope :for_lines, ->(line_ids) { where(line_id: line_ids) }
  scope :for_route, ->(route) { where(route_id: route.id) }

  scope :after, ->(start_date) { where('date >= ?', start_date) }
  scope :before, ->(end_date) { where('date <= ?', end_date) }

  scope :between, lambda { |start_date, end_date|
    if start_date && end_date
      where "date BETWEEN ? AND ?", start_date, end_date
    elsif start_date
      after start_date
    elsif end_date
      before end_date
    end
  }

  def self.compute_for_referential(referential, line_ids: [])
    Chouette::Benchmark.measure 'journey_pattern_courses_by_date.referential', referential: referential.id do
      referential.switch do
        clean_previous_stats(line_ids)
        ActiveRecord::Base.cache do
          ActiveRecord::Base.transaction do
            selected_lines(referential, line_ids).find_each do |line|
              Chouette::Benchmark.measure 'line', line: line.id do
                routes = referential.routes.where(line_id: line.id)
                if routes.exists?
                  routes.includes(:journey_patterns).find_each do |route|
                    compute_for_route(route, referential: referential)
                  end
                else
                  fill_blanks_for_empty_line line, referential: referential
                end
              end
            end
          end
        end
      end
    end
  end

  def self.selected_lines(referential, ids)
    if ids.empty?
      referential.lines.select(:id)
    else
      referential.lines.where(id: ids)
    end
  end

  def self.clean_previous_stats(line_ids)
    if line_ids.empty?
      delete_all
    else
      where(line_id: line_ids).delete_all
    end
  end

  def self.compute_for_route(route, referential: nil)
    journey_patterns = route.journey_patterns
    if journey_patterns.exists?
      journey_patterns.select(:id, :route_id).find_each do |journey_pattern|
        populate_for_journey_pattern journey_pattern, referential: referential
        fill_blanks_for_journey_pattern journey_pattern, referential: referential
      end
    else
      fill_blanks_for_empty_route route, referential: referential
    end
  end

  def self.populate_for_journey_pattern(journey_pattern, referential: nil)
    route_id = journey_pattern.route_id
    line_id = journey_pattern.route.line_id

    bulk_insert do |worker|
      JourneyPatternOfferService.new(
        journey_pattern,
        referential: referential
      ).circulation_dates.each do |date, count|
        worker.add(
          journey_pattern_id: journey_pattern.id,
          route_id: route_id,
          line_id: line_id,
          date: date,
          count: count
        )
      end
    end
  end

  def self.fill_blanks_for_empty_line(line, referential:)
    service = JourneyPatternOfferService.new(
      nil,
      referential: referential,
      line: line
    )

    bulk_insert do |worker|
      service.period_start.upto(service.period_end) do |date|
        worker.add(
          date: date,
          count: 0,
          journey_pattern_id: nil,
          route_id: nil,
          line_id: line.id
        )
      end
    end
  end

  def self.fill_blanks_for_empty_route(route, referential:)
    service = JourneyPatternOfferService.new(
      nil,
      referential: referential,
      route: route
    )

    bulk_insert do |worker|
      service.period_start.upto(service.period_end) do |date|
        worker.add(
          date: date,
          count: 0,
          journey_pattern_id: nil,
          route_id: route.id,
          line_id: route.line_id
        )
      end
    end
  end

  def self.fill_blanks_for_journey_pattern(journey_pattern, referential: nil)
    scope = for_journey_pattern(journey_pattern)

    service = JourneyPatternOfferService.new(
      journey_pattern,
      referential: referential
    )

    previous_date = service.period_start.prev_day
    route_id = journey_pattern.route_id
    line_id = journey_pattern.route.line_id
    bulk_insert do |worker|
      scope.order('date ASC').each do |stat|
        while previous_date < stat.date - 1
          previous_date = previous_date.next
          worker.add(
            date: previous_date,
            count: 0,
            journey_pattern_id: journey_pattern.id,
            route_id: route_id,
            line_id: line_id
          )
        end
        previous_date = stat.date
      end
      while previous_date < service.period_end
        previous_date = previous_date.next
        worker.add(
          date: previous_date,
          count: 0,
          journey_pattern_id: journey_pattern.id,
          route_id: route_id,
          line_id: line_id
        )
      end
    end
  end

  def self.holes_for_line(line)
    for_line(line).group('date, line_id').having('SUM(count) = 0').select(:date).order(:date)
  end
end
