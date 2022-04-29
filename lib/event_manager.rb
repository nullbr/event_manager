require 'csv'
puts 'Event Manager Initialized!'

contents = CSV.open('event_attendees.csv',
                    headers: true,
                    header_converters: :symbol)

contents.each do |row|
  name = row[:first_name]
  zipcode = row[:zipcode]

  # if the zip code is ex

  puts "#{name} #{zipcode}"
end
