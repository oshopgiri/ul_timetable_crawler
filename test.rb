require_relative 'timetable'

parsed_contents = Timetable::Parser.parse(
  html_content: Timetable::Downloader.for(year: 1, course_code: 'LM338')
)

puts parsed_contents
