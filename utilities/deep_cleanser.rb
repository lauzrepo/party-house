def deep_cleanser(input)
    input&.transform_values do |v|
      if v === true || v === false
        v.to_s
      elsif v.is_a?(Hash)
        deep_cleanser(v)
      elsif v.is_a?(Array)
        clean_array = v.reject(&:empty?).map do |element|
          element.is_a?(Hash) ? deep_cleanser(element) : element
        end
        clean_array.empty? ? nil : clean_array
      else
        v
      end
    end&.compact
  end
  