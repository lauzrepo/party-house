# Workato Recipe Generation — Claude Code Guide

This repository is the source of truth for Workato integration recipes.
All recipes are authored as YAML files, validated locally, and deployed to
Workato via the RLM API — no Workato UI editing required.

---

## Repository layout

```
workato/
  manifest.json               # Package manifest — list of all recipes & connections
  recipes/
    *.recipe.yaml             # One file per recipe
  connections/
    connections.yaml          # Named connection slots (no credentials stored here)
scripts/
  validate_recipes.rb         # Validate recipe YAML before committing
  deploy_recipes.rb           # Deploy to Workato via API
```

---

## Recipe YAML format

Every recipe file must sit under `workato/recipes/` and end in `.recipe.yaml`.

### Skeleton

```yaml
recipe:
  name: "Human-readable recipe name"
  description: >
    One or two sentences explaining what this recipe does.
  version: 1          # Integer — bump when making breaking changes
  active: true        # Whether to activate recipe on deploy

  trigger:
    provider: <provider_slug>    # e.g. salesforce, workato, http, slack
    name: <trigger_action>       # e.g. new_updated_object, new_webhook_payload
    connection: <connection_name> # Must match a name in connections/connections.yaml
                                  # Use ~ (null) for Workato-native triggers
    input:
      # Provider-specific input fields
    output_fields:
      # Declare fields emitted by the trigger so steps can reference them

  steps:
    - step_id: 1
      type: action | if | foreach | error_monitor
      # ... (see step types below)
```

### Field referencing (Liquid templating)

Workato uses Liquid-style double-curly references:

| Expression | Meaning |
|---|---|
| `{{trigger.FieldName}}` | Field from the trigger output |
| `{{step_N.field}}` | Output from step number N |
| `{{foreach.field}}` | Current item in a foreach loop |
| `{{now}}` | Current UTC timestamp |
| `{{env.VAR_NAME}}` | Environment variable injected at runtime |

Liquid filters work as expected: `{{trigger.Amount | number_to_currency}}`,
`{{trigger.CreatedDate | date: "%Y-%m-%d"}}`.

---

## Step types

### `action` — call a connector action

```yaml
- step_id: 1
  type: action
  provider: slack                   # Connector slug
  name: post_message                # Action name within the connector
  connection: slack_workspace       # Named connection from connections.yaml
  description: "Optional note"
  input:
    channel_type: channel
    channel: "#general"
    message: "Hello {{trigger.Name}}"
```

### `if` — conditional branching

```yaml
- step_id: 2
  type: if
  description: "Check condition"
  condition:
    operand_1: "{{trigger.Status}}"
    operator: equals           # equals | not_equals | greater_than | less_than | contains
    operand_2: "Active"
  # AND / OR across multiple conditions:
  # condition:
  #   all:                     # all = AND
  #     - operand_1: ...
  #   any:                     # any = OR
  #     - operand_1: ...
  on_true:
    - step_id: 3
      type: action
      # ...
  on_false:
    - step_id: 4
      type: action
      # ...
```

### `foreach` — loop over a list

```yaml
- step_id: 5
  type: foreach
  description: "Iterate records"
  input:
    list: "{{step_1.data}}"    # Must be an array field
    batch_size: 10             # Optional; default is 1
  steps:
    - step_id: 6
      type: action
      # Use {{foreach.field}} to access the current item
```

### `error_monitor` — try/catch

```yaml
- step_id: 7
  type: error_monitor
  steps:
    - step_id: 8
      type: action
      # ... steps to monitor
  on_error:
    - step_id: 9
      type: action
      provider: slack
      name: post_message
      connection: slack_workspace
      input:
        channel: "#alerts"
        message: "Recipe error: {{error.message}}"
```

---

## Common providers & actions

| Provider slug | Common actions |
|---|---|
| `workato` | `new_webhook_payload`, `scheduled_trigger` |
| `salesforce` | `new_updated_object`, `create_object`, `update_object`, `search_objects` |
| `slack` | `post_message`, `create_channel`, `invite_to_channel` |
| `postgresql` | `select_rows`, `insert_row`, `upsert_row`, `update_rows` |
| `http` | `request` (method: GET/POST/PUT/DELETE/PATCH) |
| `workday` | `get_worker`, `create_worker`, `update_worker` |
| `netsuite` | `create_record`, `update_record`, `search_records` |
| `jira` | `create_issue`, `update_issue`, `search_issues` |
| `gmail` | `send_email`, `new_email` |

---

## Adding a new connection

1. Open `workato/connections/connections.yaml`
2. Add an entry with the logical name, provider, and environment variable
   placeholders for each environment.
3. Reference the logical name in your recipe's `connection:` field.
4. Set the actual Workato connection ID in your CI/CD secrets as the
   matching `WORKATO_CONN_*` variable.

**Never commit real credentials or connection IDs to git.**

---

## Validation

Run before committing:

```bash
ruby scripts/validate_recipes.rb
# or validate a single file:
ruby scripts/validate_recipes.rb workato/recipes/my_recipe.recipe.yaml
```

---

## Deployment

```bash
# Deploy all recipes to dev workspace
WORKATO_API_TOKEN=xxx ruby scripts/deploy_recipes.rb

# Deploy to prod
WORKATO_API_TOKEN=xxx DEPLOY_ENV=prod WORKATO_FOLDER_ID=12345 ruby scripts/deploy_recipes.rb

# Deploy a single recipe
WORKATO_API_TOKEN=xxx ruby scripts/deploy_recipes.rb workato/recipes/webhook_to_slack.recipe.yaml
```

---

## How Claude should generate recipes

When asked to create a new Workato recipe, Claude should:

1. **Clarify the trigger** — What event starts the recipe? (webhook, scheduled,
   Salesforce event, new email, etc.)
2. **Clarify the actions** — What happens next? List each step in plain English
   before writing YAML.
3. **Use only named connections** declared in `connections/connections.yaml`.
   If a new connector is needed, add it there first.
4. **Follow the file naming convention**: `workato/recipes/<snake_case_name>.recipe.yaml`
5. **Register the recipe** in `workato/manifest.json`.
6. **Run validation** (`ruby scripts/validate_recipes.rb`) and fix any errors
   before committing.
7. **Write a clear description** in the recipe's `description:` field — this
   is the documentation for the integration.

### Prompt patterns that work well

```
"Create a Workato recipe that triggers when a new Jira issue is created with
 priority=High, then posts a formatted message to Slack #engineering and
 creates a matching record in our PostgreSQL incidents table."

"Write a recipe that polls the GitHub API every hour for new merged PRs in
 the party-house repo and inserts them into postgres_warehouse.merged_prs."

"Generate a recipe that listens for a Workato webhook, validates the payload
 has a required 'api_key' header field, and if valid forwards the payload to
 our internal HTTP endpoint."
```
