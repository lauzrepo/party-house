#!/usr/bin/env ruby
# validate_recipes.rb
#
# Validates all Workato recipe YAML files in workato/recipes/ against a
# structural schema before committing or deploying.  Catches common mistakes
# early: missing required fields, unsupported step types, etc.
#
# Usage:
#   ruby scripts/validate_recipes.rb
#   ruby scripts/validate_recipes.rb workato/recipes/my_recipe.recipe.yaml

require 'yaml'
require 'json'

REQUIRED_RECIPE_KEYS   = %w[name description version active trigger steps].freeze
REQUIRED_TRIGGER_KEYS  = %w[provider name].freeze
VALID_STEP_TYPES       = %w[action if foreach error_monitor].freeze

RECIPES_DIR = File.join(__dir__, '..', 'workato', 'recipes')

errors   = []
warnings = []
files    = ARGV.any? ? ARGV : Dir.glob(File.join(RECIPES_DIR, '**', '*.recipe.yaml'))

abort "No recipe files found in #{RECIPES_DIR}" if files.empty?

files.each do |file_path|
  puts "Validating: #{file_path}"

  begin
    doc = YAML.safe_load(File.read(file_path), permitted_classes: [Symbol])
  rescue Psych::SyntaxError => e
    errors << "#{file_path}: YAML parse error — #{e.message}"
    next
  end

  recipe = doc&.dig('recipe')
  unless recipe
    errors << "#{file_path}: missing top-level 'recipe:' key"
    next
  end

  # Check required top-level keys
  REQUIRED_RECIPE_KEYS.each do |key|
    errors << "#{file_path}: missing required key 'recipe.#{key}'" unless recipe.key?(key)
  end

  # Validate version is an integer
  if recipe['version'] && !recipe['version'].is_a?(Integer)
    errors << "#{file_path}: 'recipe.version' must be an integer"
  end

  # Validate trigger
  trigger = recipe['trigger'] || {}
  REQUIRED_TRIGGER_KEYS.each do |key|
    errors << "#{file_path}: missing required key 'recipe.trigger.#{key}'" unless trigger.key?(key)
  end

  # Validate steps
  steps = recipe['steps'] || []
  if steps.empty?
    warnings << "#{file_path}: recipe has no steps"
  else
    steps.each_with_index do |step, i|
      step_label = "recipe.steps[#{i}] (step_id: #{step['step_id'] || 'unknown'})"

      unless step.key?('type')
        errors << "#{file_path}: #{step_label} missing 'type'"
        next
      end

      unless VALID_STEP_TYPES.include?(step['type'])
        errors << "#{file_path}: #{step_label} has invalid type '#{step['type']}'. " \
                  "Valid types: #{VALID_STEP_TYPES.join(', ')}"
      end

      if step['type'] == 'action'
        %w[provider name].each do |key|
          errors << "#{file_path}: #{step_label} missing '#{key}'" unless step.key?(key)
        end
        warnings << "#{file_path}: #{step_label} has no 'connection' — intentional?" unless step.key?('connection')
      end

      if step['type'] == 'foreach'
        unless step.dig('input', 'list')
          errors << "#{file_path}: #{step_label} missing 'input.list'"
        end
        unless step['steps']&.any?
          warnings << "#{file_path}: #{step_label} foreach has no inner steps"
        end
      end

      if step['type'] == 'if'
        unless step.key?('condition')
          errors << "#{file_path}: #{step_label} if-step missing 'condition'"
        end
        warnings << "#{file_path}: #{step_label} if-step has no 'on_true' branch" unless step.key?('on_true')
        warnings << "#{file_path}: #{step_label} if-step has no 'on_false' branch" unless step.key?('on_false')
      end
    end
  end
end

puts "\n"
puts "=" * 60

if warnings.any?
  puts "WARNINGS (#{warnings.size}):"
  warnings.each { |w| puts "  ⚠  #{w}" }
  puts
end

if errors.any?
  puts "ERRORS (#{errors.size}):"
  errors.each { |e| puts "  ✗  #{e}" }
  puts
  puts "Validation FAILED — fix errors before deploying."
  exit 1
else
  puts "✓ All #{files.size} recipe(s) passed validation."
  exit 0
end
