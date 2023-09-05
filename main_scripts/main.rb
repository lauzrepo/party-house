require_relative '../utilities/deep_cleanser'
require 'json'

json_file_path = File.join(__dir__, 'json', 'json_payload.json')
json_payload = JSON.parse(File.read(json_file_path))

json_list_file_path = File.join(__dir__, 'json', 'json_list.json')
json_list_payload = JSON.parse(File.read(json_list_file_path))

cleaned_results = deep_cleanser(json_payload)

cleaned_list = deep_cleanser(json_list_payload)

puts cleaned_results

puts cleaned_list