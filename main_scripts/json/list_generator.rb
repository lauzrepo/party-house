require 'json'
require 'faker'

user_data = {
  "users": []
}

100.times do |id|
  user_data[:users] << {
    "id": id + 1,
    "name": Faker::Name.name,
    "age": rand(18..60),
    "email": Faker::Internet.email,
    "test": nil
  }
end

File.open('main_scripts/json/json_list.json', 'w') do |file|
  file.write(JSON.pretty_generate(user_data))
end

puts "User data generated and saved to 'json_list.json'"
