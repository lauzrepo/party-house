#!/usr/bin/env ruby
# deploy_recipes.rb
#
# Deploys Workato recipes from the local YAML package to a Workato workspace
# using the Workato Recipe Lifecycle Management (RLM) API.
#
# Prerequisites:
#   gem install httparty   (or: bundle install with the Gemfile below)
#
# Required environment variables:
#   WORKATO_API_TOKEN   — Workato API token (Settings → API Clients)
#   WORKATO_BASE_URL    — e.g. https://app.workato.com  (default if unset)
#   WORKATO_FOLDER_ID   — Folder ID to deploy recipes into (optional)
#   DEPLOY_ENV          — "dev" or "prod" (default: "dev")
#
# Usage:
#   WORKATO_API_TOKEN=xxx ruby scripts/deploy_recipes.rb
#   WORKATO_API_TOKEN=xxx DEPLOY_ENV=prod ruby scripts/deploy_recipes.rb
#   WORKATO_API_TOKEN=xxx ruby scripts/deploy_recipes.rb workato/recipes/my_recipe.recipe.yaml

require 'yaml'
require 'json'
require 'net/http'
require 'uri'

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
BASE_URL    = ENV.fetch('WORKATO_BASE_URL', 'https://app.workato.com')
API_TOKEN   = ENV['WORKATO_API_TOKEN']
FOLDER_ID   = ENV['WORKATO_FOLDER_ID']   # optional
DEPLOY_ENV  = ENV.fetch('DEPLOY_ENV', 'dev')

RECIPES_DIR    = File.join(__dir__, '..', 'workato', 'recipes')
CONNECTIONS_FILE = File.join(__dir__, '..', 'workato', 'connections', 'connections.yaml')

abort "ERROR: WORKATO_API_TOKEN environment variable is not set." unless API_TOKEN

# ---------------------------------------------------------------------------
# HTTP helper
# ---------------------------------------------------------------------------
def api_request(method, path, body = nil)
  uri  = URI.parse("#{BASE_URL}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.read_timeout = 30

  klass = { get: Net::HTTP::Get, post: Net::HTTP::Post, put: Net::HTTP::Put }[method]
  req = klass.new(uri.request_uri)
  req['Authorization']  = "Bearer #{API_TOKEN}"
  req['Content-Type']   = 'application/json'
  req['x-user-token']   = API_TOKEN   # some endpoints use this header

  req.body = body.to_json if body
  http.request(req)
rescue => e
  abort "HTTP request failed: #{e.message}"
end

# ---------------------------------------------------------------------------
# Connection resolver — maps logical name → Workato connection ID for env
# ---------------------------------------------------------------------------
def load_connection_map(env)
  doc = YAML.safe_load(File.read(CONNECTIONS_FILE), permitted_classes: [Symbol])
  map = {}
  (doc['connections'] || []).each do |conn|
    env_id = conn.dig('environments', env)
    if env_id.nil? || env_id.start_with?('${')
      puts "  ⚠  Connection '#{conn['name']}' has no resolved ID for env=#{env} — skipping"
    else
      map[conn['name']] = env_id
    end
  end
  map
end

# ---------------------------------------------------------------------------
# Recipe transformer — converts YAML recipe doc → Workato API payload
# ---------------------------------------------------------------------------
def build_api_payload(recipe_doc, connection_map, folder_id)
  r = recipe_doc['recipe']

  payload = {
    recipe: {
      name:        r['name'],
      description: r['description'],
      version:     r['version'],
      folder_id:   folder_id&.to_i,
      # The full recipe definition is sent as a structured hash.
      # In a production integration you would serialize steps into Workato's
      # internal DSL format here.  For the PoC we attach the raw YAML as
      # metadata and print the structure.
      trigger:     r['trigger'],
      steps:       r['steps']
    }.compact
  }

  payload
end

# ---------------------------------------------------------------------------
# Upsert (create or update) a recipe via the Workato API
# ---------------------------------------------------------------------------
def upsert_recipe(payload, recipe_name)
  # 1. Search for existing recipe by name
  search_resp = api_request(:get, "/api/recipes?name=#{URI.encode_www_form_component(recipe_name)}")
  if search_resp.code.to_i == 200
    existing = JSON.parse(search_resp.body)
    recipe_id = existing.dig('items', 0, 'id')
  end

  if recipe_id
    # 2a. Update existing recipe
    puts "  → Updating existing recipe (id=#{recipe_id})"
    resp = api_request(:put, "/api/recipes/#{recipe_id}", payload)
  else
    # 2b. Create new recipe
    puts "  → Creating new recipe"
    resp = api_request(:post, "/api/recipes", payload)
  end

  code = resp.code.to_i
  if code.between?(200, 299)
    result = JSON.parse(resp.body)
    puts "  ✓ Success — recipe id=#{result.dig('id') || result.dig('recipe', 'id')}"
    result
  else
    puts "  ✗ Failed (HTTP #{code}): #{resp.body[0, 300]}"
    nil
  end
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
puts "Deploy environment : #{DEPLOY_ENV}"
puts "Workato workspace  : #{BASE_URL}"
puts "Target folder ID   : #{FOLDER_ID || '(root)'}"
puts

connection_map = load_connection_map(DEPLOY_ENV)
files = ARGV.any? ? ARGV : Dir.glob(File.join(RECIPES_DIR, '**', '*.recipe.yaml'))

abort "No recipe files found in #{RECIPES_DIR}" if files.empty?

results = { success: 0, failed: 0 }

files.each do |file_path|
  puts "Deploying: #{file_path}"

  begin
    doc = YAML.safe_load(File.read(file_path), permitted_classes: [Symbol])
  rescue Psych::SyntaxError => e
    puts "  ✗ YAML parse error: #{e.message}"
    results[:failed] += 1
    next
  end

  payload = build_api_payload(doc, connection_map, FOLDER_ID)
  result  = upsert_recipe(payload, doc.dig('recipe', 'name'))

  if result
    results[:success] += 1
  else
    results[:failed] += 1
  end

  puts
end

puts "=" * 60
puts "Deployed: #{results[:success]} succeeded, #{results[:failed]} failed"
exit(results[:failed] > 0 ? 1 : 0)
