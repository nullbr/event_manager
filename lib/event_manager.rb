require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def get_reg_time(time)
  time = "#{time[0..5]}20#{time[6..13]}"
  Time.strptime(time, '%m/%d/%Y %k:%M')
end

def get_peak(hash)
  sorted = hash.sort_by { |_key, value| value }
  sorted = sorted.last(3)
  [sorted[0][0], sorted[1][0], sorted[2][0]]
end

def clean_zipcode(zipcode)
  # if zip code was not filled, it becomes the wrong zip code default of 00000
  # if the zip code is lass than five digits, add zeros the the front until it becomes five digits
  # if the zip code is more than five digits, truncate it to the five digits
  # if the zip code is exactly five digits, assume that it is ok
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(n)
  n = n.to_s.tr('^0-9', '')

  if n.size == 10
    # format number to standard phone number format
    "(#{n[0..2]})#{n[3..5]}-#{n[6..10]}"
  elsif n.size == 11 && n[0] == '1'
    # format number to standard phone number format with country digit
    "+1(#{n[1..3]})#{n[4..6]}-#{n[7..11]}"
  else
    # If the phone number is less than 10 digits, assume that it is a bad number
    # If the phone number is 11 digits and the first number is not 1, then it is a bad number
    # If the phone number is more than 11 digits, assume that it is a bad number
    ''
  end
end

def legislator_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  civic_info.representative_info_by_address(
    address: zipcode,
    levels: 'country',
    roles: %w[legislatorUpperBody legislatorLowerBody]
  ).officials
rescue StandardError
  'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open('event_attendees.csv',
                    headers: true,
                    header_converters: :symbol)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours = {}
weekdays = {}

#=begin
contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  # legislators = legislator_by_zipcode(zipcode)

  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id,form_letter)

  time = get_reg_time(row[:regdate])

  if hours[time.hour].nil?
    hours[time.hour] = 1
  else
    hours[time.hour] += 1
  end

  if weekdays[time.wday].nil?
    weekdays[time.wday] = 1
  else
    weekdays[time.wday] += 1
  end
end

peak_hours = get_peak(hours)
peak_weekdays = get_peak(weekdays)
weekdays = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

days = []
peak_weekdays.each { |day| days << weekdays[day.to_i] }

puts "Peak registration hours were: #{peak_hours.join(', ')}"
puts "Peak registration Days were: #{days.join(', ')}"