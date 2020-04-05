require 'nokogiri'
require 'tod'

class Timetable::Parser
  DAYS_OF_WEEK = {
    0 => 'monday',
    1 => 'tuesday',
    2 => 'wednesday',
    3 => 'thursday',
    4 => 'friday',
    5 => 'saturday'
  }.freeze

  def self.parse(html_content:)
    document = Nokogiri::HTML.parse(html_content)
    parsed_contents = []

    table_rows = document.css('table#MainContent_CourseTimetableGridView > tr').to_a

    (1..(table_rows.length - 1)).each do |index|
      table_rows[index].css('td').each_with_index do |table_cell, day_of_week_index|
        cell_contents = table_cell.css('font').first.children.to_html.gsub(/[[:space:]]/, ' ').strip
        next if cell_contents.empty?

        cell_contents = cell_contents.split('<br>').map(&:strip)
        cell_contents.each_slice(6) do |time, lecture_details, professor, lecture_room, weeks, _|
          lecture_details = lecture_details.split('-').map(&:strip)
          weeks = weeks.split(',').map do |week_range|
            range = week_range.split('-').map(&:to_i)
            if range[1].nil?
              [range[0]]
            else
              (range[0]..range[1]).to_a
            end
          end.flatten

          time = time.split('-').map(&:strip)
          start_time = Tod::TimeOfDay.parse time[0]
          end_time = Tod::TimeOfDay.parse time[1]
          timeline = self.generate_timeline(start_time: start_time, end_time: end_time)

          timeline.each do |timeline_start, timeline_end|
            parsed_contents << {
              weeks: weeks,
              day_of_week: DAYS_OF_WEEK[day_of_week_index],
              module_code: lecture_details[0],
              start_time: start_time >= timeline_start ? start_time.to_s : timeline_start.to_s,
              end_time: end_time <= timeline_end ? end_time.to_s : timeline_end.to_s,
              lecture_type: lecture_details[1],
              batch_code: lecture_details[2] || '',
              lecture_room: lecture_room,
              professor: professor
            }
          end
        end
      end
    end

    parsed_contents
  end

  private

    def self.generate_timeline(start_time:, end_time:)
        timeline_start = if start_time.to_i % 3600 == 0
          start_time
        else
          start_time - (start_time.to_i % 3600)
        end

        timeline_end = if end_time.to_i % 3600 == 0
          end_time
        else
          end_time + (3600 - (end_time.to_i % 3600))
        end

        if (timeline_end - timeline_start).to_i > 3600
          timeline = []
          (1..((timeline_end - timeline_start).to_i / 3600)).each do |hour|
            timeline << [timeline_start, timeline_start + 3600]
            timeline_start = timeline_start + 3600
          end

          timeline
        else
          [[timeline_start, timeline_end]]
        end
    end
end
