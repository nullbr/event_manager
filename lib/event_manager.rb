require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  # if zip code was not filled, it becomes the wrong zip code default of 00000
  # if the zip code is lass than five digits, add zeros the the front until it becomes five digits
  # if the zip code is more than five digits, truncate it to the five digits
  # if the zip code is exactly five digits, assume that it is ok
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(n)
  n = n.to_s.tr("^0-9", '')

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

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  legislators = legislator_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end