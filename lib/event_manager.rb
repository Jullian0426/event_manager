require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  cleaned_number = phone_number.gsub(/\D/, '')

  return '0000000000' unless [10, 11].include?(cleaned_number.length)

  if cleaned_number.length == 11 && cleaned_number.start_with?('1')
    return cleaned_number[1..]
  end

  cleaned_number.length == 10 ? cleaned_number : '0000000000'
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def time_targeting(dates)
  hours = []

  dates.each do |date|
    date_time = DateTime.strptime(date, '%m/%d/%y %H:%M')
    hours << date_time.hour
  end

  hour_counts = hours.each_with_object(Hash.new(0)) { |hour, counts| counts[hour] += 1 }

  sorted_hour_counts = hour_counts.sort_by { |hour, count| -count }
  top_three_hours = sorted_hour_counts.first(3).map(&:first)

  puts "Most frequent hours: #{top_three_hours.inspect}"

  top_three_hours
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees_full.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

dates = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  date = row[:regdate]
  dates << date
  phone_number = clean_phone_number(row[:homephone])
  # legislators = legislators_by_zipcode(zipcode)

  # form_letter = erb_template.result(binding)

  # save_thank_you_letter(id,form_letter)
end

time_targeting(dates)