# coding: utf-8
# execution example: rake 'referential:create[3, 1896, '01-01-2017', '01-04-2017']'

namespace :referential do
  desc 'Create a referential and accompanying data'
  task :create, [:workbench_id, :start_date, :end_date] => [:environment] do |t, args|
    args.with_defaults(workbench_id: 1, start_date: Date.today.strftime, end_date: (Date.today + 30).strftime)

    Referential.transaction do
      workbench = Workbench.find_by!(id: args[:workbench_id])
      line = workbench.line_referential.lines.order(Arel.sql('random()')).first
      name = "Referential #{Faker::Name.unique.name}"

      referential = workbench.referentials.create!(name: name, slug: name.downcase.parameterize.underscore, organisation: workbench.organisation,
                                                   prefix: Faker::Lorem.unique.characters(10))
      ReferentialMetadata.create!(referential: referential, line_ids: [line.id], periodes: [Date.parse(args[:start_date])..Date.parse(args[:end_date])])
      referential.switch

      print "✓ Created Referential ".green, name, "(#{referential.id})".blue, "\n"
      puts "  For inspection of data in the console, do a: `Referential.last.switch'".blueish

      stop_areas = workbench.stop_area_referential.stop_areas.last(10)

      4.times do |i|
        name = Faker::Name.unique.name
        route_attrs = { line: line, name: "Route #{name}" }

        if i.even?
          route_attrs[:wayback] = :outbound
          route = Chouette::Route.create!(route_attrs)
          route.stop_areas = stop_areas
        else
          route_attrs[:wayback] = :inbound
          route_attrs[:opposite_route] = Chouette::Route.last if i == 3
          route = Chouette::Route.create!(route_attrs)
          route.stop_areas = stop_areas.reverse
        end
        route.save!
        print "  ✓ Created Route ".green, route.name, "(#{route.id}), ".blue, "Line (#{line.id}) has #{line.routes.count} routes\n"

        journey_pattern = Chouette::JourneyPattern.create!(route: route, name: "Journey Pattern #{Faker::Name.unique.name}")
        print "✓ Created JourneyPattern ".green, journey_pattern.name, "(#{journey_pattern.id})".blue, "\n"

        journey_pattern.stop_points = stop_areas.inject([]) { |stop_points, stop_area| stop_points += stop_area.stop_points }

        time_tables = []
        2.times do |j|
          name = "Test #{Faker::Name.unique.name}"
          time_table = Chouette::TimeTable.create!(comment: name, start_date: Date.parse(args[:start_date]) + j.days,
                                                   end_date: Date.parse(args[:end_date]) - j.days)
          print "✓ Created TimeTable ".green, time_table.comment, "(#{time_table.id})".blue, "\n"
          time_tables << time_table
        end

        25.times do |j|
          vehicle_journey = Chouette::VehicleJourney.create!(journey_pattern: journey_pattern, route: route, number: Faker::Number.unique.number(4), time_tables: time_tables)
          print "✓ Created VehicleJourney ".green, vehicle_journey.number, "(#{vehicle_journey.id})".blue, "\n"

          time = Time.current.at_noon + j.minutes
          journey_pattern.stop_points.each_with_index do |stop_point, k|
            vehicle_journey.vehicle_journey_at_stops.create!(stop_point: stop_point, arrival_time: time + k.minutes, departure_time: time + k.minutes + 30.seconds)
          end
        end

      end

      referential.update(ready: true)
    end
  end

  def update_checksums_in_referential_for_klass klass
    i = 0
    j = 0
    prev_size = 1
    head =  "Updating checksums for #{klass.name}: "
    print head
    print "⎯"*(80-head.size)
    print "  "
    count = klass.count
    klass.cache do
      klass.find_in_batches(batch_size: 500) do |batch|
        klass.transaction do
          batch.each do |o|
            o.update_checksum!
            if j%10 == 0
              out = "#{"\b"*prev_size}\e[33m#{@thing[i]}\e[0m (#{j}/#{count})"
              prev_size = out.size - prev_size - 9
              print out
              i = (i+1) % @thing.size
            end
            j += 1
          end
        end
      end
    end

    print "#{"\b"*prev_size}\e[32m✓\e[0m (#{count}/#{count})\n"
  end

  def update_checksums_for_referential referential, klasses=nil
    @thing = %w(\\ | / —)
    unless klasses
      Referential.force_register_models_with_checksum
      klasses = Referential.models_with_checksum
    end
    puts "\n \e[33m***\e[0m Referential #{referential.name}"
    referential.switch do
      klasses.each do |klass|
        update_checksums_in_referential_for_klass klass
      end
    end
  end

  def each_relevant_referential
    referentials = Referential.not_in_referential_suite
    referentials += Workbench.all.map { |w| w.output.current }.compact
    referentials.sort_by(&:created_at).reverse.each do |referential|
      yield referential
    end
  end

  desc 'Update all the checksums in the given referential'
  task :update_checksums_in_referential, [:id] => :environment do |t, args|
    referential = Referential.find(args[:id])
    update_checksums_for_referential referential
  end

  desc 'Update all the checksums in the given organisation'
  task :update_checksums_in_organisation, [:organisation_id] => :environment do |t, args|
    Organisation.find(args[:organisation_id]).referentials.find_each do |referential|
      update_checksums_for_referential referential
    end
  end

  desc 'Update all relevant checksums for JourneyPattern'
  task :update_journey_patterns_checksums => :environment do |t, args|
    each_relevant_referential do |referential|
      update_checksums_for_referential referential, [Chouette::JourneyPattern]
    end
  end

  desc 'Update all relevant checksums for VehicleJourney'
  task :update_vehicle_journeys_checksums => :environment do
    each_relevant_referential do |referential|
      update_checksums_for_referential referential, [Chouette::VehicleJourney]
    end
  end

  desc 'Update all relevant checksums for RoutingConstraintZone'
  task :update_routing_constraint_zones_checksums => :environment do |t, args|
    each_relevant_referential do |referential|
      faulty = []
      referential.switch do
        Chouette::RoutingConstraintZone.find_each do |rcz|
          if rcz.stop_point_ids != rcz.stop_points.map(&:id)
            faulty << rcz.id
          end
        end
        update_checksums_for_referential referential, [Chouette::RoutingConstraintZone.where(id: faulty)]
      end
    end
  end
end
