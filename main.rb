require 'csv'
require_relative 'timetable'

OUTPUT_FILE = "./result-#{Time.now.to_i}.csv"
File.delete(OUTPUT_FILE) if File.exist?(OUTPUT_FILE)

CSV.open(OUTPUT_FILE, 'wb') do |csv|
  csv << [
    'year',
    'course_code',
    'course_name',
    'weeks',
    'day_of_week',
    'module_code',
    'start_time',
    'end_time',
    'lecture_type',
    'batch_code',
    'lecture_room',
    'professor'
  ]

  CSV.foreach('./courses.csv') do |course_code, course_name|
    (1..5).each do |year|
      puts "#{year} - #{course_code}"

      parsed_contents = Timetable::Parser.parse(
        html_content: Timetable::Downloader.for(year: year, course_code: course_code)
      )

      parsed_contents.each do |parsed_content|
        csv << [
          year,
          course_code,
          course_name,
          parsed_content[:weeks],
          parsed_content[:day_of_week],
          parsed_content[:module_code],
          parsed_content[:start_time],
          parsed_content[:end_time],
          parsed_content[:lecture_type],
          parsed_content[:batch_code],
          parsed_content[:lecture_room],
          parsed_content[:professor]
        ]
      end
    end
  end
end
