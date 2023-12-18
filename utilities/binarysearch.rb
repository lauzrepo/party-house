require 'json'

# Sample array of sorted JSON objects based on the 'id' key
json_array = [
  '{"id": 1, "name": "John", "age": 25}',
  '{"id": 2, "name": "Alice", "age": 30}',
  '{"id": 3, "name": "Bob", "age": 22}'
]

# Parse JSON strings into Ruby hashes
hash_array = json_array.map { |json| JSON.parse(json) }

# Binary search function based on the 'id' key
def binary_search(array, key, target)
  low = 0
  high = array.length - 1

  while low <= high
    mid = (low + high) / 2
    mid_value = array[mid][key]

    if mid_value == target
      return array[mid]
    elsif mid_value < target
      low = mid + 1
    else
      high = mid - 1
    end
  end

  return nil  # Target not found
end

# Example: Binary search for an object with 'id' equal to 2
result = binary_search(hash_array, 'id', 2)

if result
  puts "Object found: #{result}"
else
  puts "Object not found."
end
