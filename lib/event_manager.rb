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
  days_of_week = []

  # Extract hours and days of the week from date strings
  dates.each do |date|
    date_time = DateTime.strptime(date, '%m/%d/%y %H:%M')
    hours << date_time.hour
    days_of_week << date_time.strftime('%A')  # '%A' gives the full name of the day
  end

  # Find the top 3 most frequent hours and days
  top_three_hours = find_top_frequencies(hours, 3)
  top_three_days = find_top_frequencies(days_of_week, 3)

  puts "Most frequent hours: #{top_three_hours.inspect}"
  puts "Most frequent days of the week: #{top_three_days.inspect}"

  [top_three_hours, top_three_days]  # Return the top three hours and days for further use
end

def find_top_frequencies(elements, top_n)
  counts = elements.each_with_object(Hash.new(0)) { |element, counts| counts[element] += 1 }
  sorted_counts = counts.sort_by { |element, count| -count }
  sorted_counts.first(top_n).map(&:first)
end


puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
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
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

time_targeting(dates)