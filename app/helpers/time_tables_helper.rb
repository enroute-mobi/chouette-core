require 'date'

module TimeTablesHelper

  def month_periode_enum(bounding_dates, years)
    if bounding_dates.empty?
      start_date = Date.today - years.years
      end_date = Date.today + years.years
    else
      start_date = (bounding_dates.min > Date.today ? Date.today : bounding_dates.min) - years.years
      end_date   = (bounding_dates.max < Date.today ? Date.today : bounding_dates.max) + years.years
    end
    
    (start_date..end_date).map(&:beginning_of_month).uniq.map(&:to_s)
  end

  def new_alt_calendar(options = {}, &block)
    raise(ArgumentError, "No year given")  unless options.has_key?(:year)
    raise(ArgumentError, "No month given") unless options.has_key?(:month)

    block                        ||= Proc.new {|d| nil}

    month_names = (!defined?(I18n) || I18n.t("date.month_names").include?("missing")) ? Date::MONTHNAMES.dup : I18n.t("date.month_names")

    defaults = {
      :table_id            => "calendar-#{options[:year]}-#{"%02d" % options[:month]}",
      :table_class         => 'calendar',
      :month_name_class    => 'monthName',
      :other_month_class   => 'outsideMonth',
      :day_name_class      => 'dayName',
      :day_class           => 'day',
      :abbrev              => false,
      :first_day_of_week   => 0,
      :accessible          => false,
      :show_today          => true,
      :previous_month_text => nil,
      :next_month_text     => nil,
      :month_header        => true,
      :calendar_title      => month_names[options[:month]],
      :summary             => "Calendrier pour #{month_names[options[:month]]} #{options[:year]}"
    }
    options = defaults.merge options

    first = Date.civil(options[:year], options[:month], 1)
    last = Date.civil(options[:year], options[:month], -1)

    first_weekday = first_day_of_week(options[:first_day_of_week])
    last_weekday = last_day_of_week(options[:first_day_of_week])

    day_names = (!defined?(I18n) || I18n.t("date.day_names").include?("missing")) ? Date::DAYNAMES : I18n.t("date.day_names")
    abbr_day_names = (!defined?(I18n) || I18n.t("date.abbr_day_names").include?("missing")) ? Date::ABBR_DAYNAMES : I18n.t("date.abbr_day_names")
    week_days = (0..6).to_a
    first_weekday.times do
      week_days.push(week_days.shift)
    end

    # TODO Use some kind of builder instead of straight HTML
    cal = %(<table id="#{options[:table_id]}" class="#{options[:table_class]}" border="0" cellspacing="0" cellpadding="0" summary="#{options[:summary]}">)
    cal << %(<thead>)

    if (options[:month_header])
      cal << %(<tr>)
      cal << %(<th class='weekNumber' scope="col"></th>)
      if options[:previous_month_text] or options[:next_month_text]
        cal << %(<th colspan="2">#{options[:previous_month_text]}</th>)
        colspan=3
      else
        colspan=7
      end
      cal << %(<th colspan="#{colspan}" class="#{options[:month_name_class]}">#{options[:calendar_title]}</th>)
      cal << %(<th colspan="2">#{options[:next_month_text]}</th>) if options[:next_month_text]
      cal << %(</tr>)
    end

    cal << %(<tr class="#{options[:day_name_class]}">)
    cal << %(<th class='weekNumber' scope="col"></th>)

    week_days.each do |wday|
      cal << %(<th id="#{th_id(Date::DAYNAMES[wday], options[:table_id])}" scope="col">)
      cal << (options[:abbrev] ? %(<abbr title="#{day_names[wday]}">#{t("calendars.days.#{Date::DAYNAMES[wday].downcase}")}</abbr>) : t("calendars.days.#{Date::DAYNAMES[wday].downcase}"))
      cal << %(</th>)
    end

    cal << "</tr></thead><tbody><tr>"

    # previous month
    beginning_of_week(first, first_weekday).upto(first - 1) do |d|
      cal << "<td class='weekNumber'>S#{d.strftime("%W").to_s}</td>" if d.wday == first_weekday
      cal << generate_other_month_cell(d, options)
    end unless first.wday == first_weekday

    first.upto(last) do |cur|
      cell_text, cell_attrs = yield cur
      cell_text  ||= cur.mday
      cell_attrs ||= {}
      cell_attrs[:headers] = th_id(cur, options[:table_id])
      cell_attrs[:class] ||= options[:day_class]
      cell_attrs[:class] += " weekend" if [0, 6].include?(cur.wday)
      today = (Time.respond_to?(:zone) && !(zone = Time.zone).nil? ? zone.now.to_date : Date.today)
      cell_attrs[:class] += " today" if (cur == today) and options[:show_today]

      cal << "<td class='weekNumber'>S#{cur.strftime("%W").to_s}</td>" if cur.wday == first_weekday

      cal << generate_cell(cell_text, cell_attrs)
      cal << "</tr><tr>" if cur.wday == last_weekday
    end

    # next month
    (last + 1).upto(beginning_of_week(last + 7, first_weekday) - 1)  do |d|
      cal << generate_other_month_cell(d, options)
    end unless last.wday == last_weekday

    cal << "</tr></tbody></table>"
    cal.respond_to?(:html_safe) ? cal.html_safe : cal
  end

  private

  def first_day_of_week(day)
    day
  end

  def last_day_of_week(day)
    if day > 0
      day - 1
    else
      6
    end
  end

  def days_between(first, second)
    if first > second
      second + (7 - first)
    else
      second - first
    end
  end

  def beginning_of_week(date, start = 1)
    days_to_beg = days_between(start, date.wday)
    date - days_to_beg
  end

  def generate_cell(cell_text, cell_attrs)
    cell_attrs = cell_attrs.map {|k, v| %(#{k}="#{v}") }.join(" ")
    "<td #{cell_attrs}>#{cell_text}</td>"
  end

  def generate_other_month_cell(date, options)
    cell_attrs = {}
    cell_attrs[:headers] = th_id(date, options[:table_id])
    cell_attrs[:class] = options[:other_month_class]
    cell_attrs[:class] += " weekend" if weekend?(date)
    cell_attrs[:title] ||= date.strftime("%W").to_i if options[:first_day_of_week] == 1

    cell_text = date.day
    if options[:accessible]
      cell_text += %(<span class="hidden"> #{month_names[date.month]}</span>)
    end

    generate_cell(date.day, cell_attrs)
  end

  # Calculates id for th element.
  #   derived from calendar_id and dow.
  #
  # Params:
  #   `day` can be either Date or DOW('Sunday', 'Monday')
  def th_id(day, calendar_id)
    return th_id(Date::DAYNAMES[day.wday], calendar_id) if day.is_a?(Date)
    "#{calendar_id}-#{day[0..2].downcase}"
  end

  def weekend?(date)
    [0, 6].include?(date.wday)
  end

  class Engine < Rails::Engine # :nodoc:
    ActiveSupport.on_load(:action_view) do
      include CalendarHelper
    end
  end if defined? Rails::Engine

end
