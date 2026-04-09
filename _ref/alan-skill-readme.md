---
name: alan
description: "Use this skill for ALL tasks involving the Alan platform, a model-driven declarative development platform by Kjerner for building data-centric business applications. Trigger whenever the user mentions Alan models, application.alan, wiring, migrations, deployments, the Alan IDE, collections, stategroups, numerical-types, derived values, permissions (can-read, can-update), commands, connectors, or working on their Alan project. Use this skill to write, review, debug, or refactor any Alan code across all file types including application.alan, migration.alan, wiring files, connector processor files, and settings.alan."
---

# Alan Platform Skill

Alan is a **model-driven, declarative, non-Turing-complete** development platform built by Kjerner. You define a data model and Alan generates a full-stack application: a graph database, a responsive web UI, SQL sync, Excel/CSV export, and an authentication system. No traditional programming — it is closer to structured configuration than code.

Read the reference files in this skill's `references/` directory for deep syntax details:
- `references/application-language.md` — Full application model syntax
- `references/wiring-and-deployment.md` — Wiring, deployment, system setup
- `references/migrations.md` — Migration syntax and patterns
- `references/connectors.md` — Connector/interface syntax
- `references/ui-annotations.md` — UI annotations and auto-webclient settings
- `references/common-patterns.md` — Forum-proven solutions for common problems

---

## Project Structure

```
project/
├── _docs/                         # Documentation (optional)
├── deployments/                   # Deployment configs (per environment, NOT in git)
├── migrations/
│   ├── from_empty/                # First-ever deploy
│   │   ├── from/                  # Empty model stub
│   │   ├── to -> ../../models/model/application.alan
│   │   └── migration.alan
│   └── from_release/              # Every subsequent deploy
│       ├── from/                  # Previous deployed model (auto-generated)
│       ├── to -> ../../models/model/application.alan
│       └── migration.alan
├── models/
│   └── model/
│       └── application.alan       # ← THE main model file
├── systems/
│   ├── server/                    # Datastore config
│   ├── client/
│   │   └── settings.alan          # UI settings (anonymous login, etc.)
│   ├── reporter/                  # Excel report generator
│   └── sessions/
│       └── config.alan            # Password auth config
├── wiring/
│   └── project.wiring             # How systems connect
├── alan                           # Alan CLI binary
├── README.md                      # App URL lives here after deploy
└── versions.json                  # Platform version pins
```

---

## IDE Workflow

The online IDE at `coder.alan-platform.com` is VS Code in the browser. Bottom-left buttons:

| Button | Action |
|--------|--------|
| **Alan Fetch** | Download/update platform tools (run first on a new project) |
| **Alan Build** | Compile model, check for errors |
| **Alan Deploy** | Publish to server (first time: choose "empty"; after: choose "migrate") |
| **Alan Show** | Open deployed app in browser |

Files auto-save when you switch between files or click any Alan button.

**First deploy sequence:** Fetch → Build → Deploy (empty) → Show

**Subsequent deploys:** Build → `Alan: Generate Migration` (from Command Palette) → review migration.alan → Deploy (migrate) → Show

---

## Application Model — Core Syntax

Every valid model requires exactly this skeleton:

```alan
users
	anonymous         // OR: dynamic: .'Users' passwords: .'Passwords' ...

interfaces

root {
	// all your data goes here
}

numerical-types
	// number unit definitions
```

### Property Types (6 total)

| Type | Description | Example |
|------|-------------|---------|
| `text` | Unbounded string | `'Name': text` |
| `number 'unit'` | Integer with declared unit | `'Price': number 'eurocent'` |
| `file` | Token + extension | `'Document': file` |
| `collection ['Key'] { }` | Key-value map (like a table) | `'Orders': collection ['ID'] { 'ID': text }` |
| `stategroup ( )` | Enumerated alternatives | `'Status': stategroup ( 'Active' { } 'Closed' { } )` |
| `group { }` | Nested namespace | `'Address': group { 'Street': text }` |

**Derived (computed, read-only) properties** use `=`:
```alan
'Total': number 'eurocent' = sum .'Lines'* .'Line total'
'Full name': text = concat ( .'First' , " " , .'Last' )
```

### Navigation Expressions

```
.'Property'          access a property on current node
?'State'             require stategroup to be in this state
>'Reference'         follow a reference to its target node
^                    move to parent node (one level up)
^^                   two levels up
$'varname'           named variable / binding
user                 the currently logged-in user node
```

### References

**Mandatory reference** (value MUST exist in target collection):
```alan
'Item': text -> ^ ^ .'Products'[]
```

**Optional reference** (may not resolve):
```alan
'Supplier': text ~> ^ .'Suppliers'[]
```

**With where-clause filter** (restricts valid targets):
```alan
'Active item': text -> ^ .'Items'[] as $'item'
	where 'is active' -> $'item'.'Status'?'Active'
```

**Sibling reference** (within same collection, for graphs):
```alan
'Next': text -> ^ sibling
```

**Reference set** (bidirectional / inverse):
```alan
// On the "one" side:
'Assigned orders': reference-set -> downstream ^ ^ .'Orders'* .'Customer' = inverse >'Customer'
// Then aggregate:
'Order count': number 'units' = count <'Assigned orders'*
```

### Collections — Key Rules

- The first property in a collection must be the **key** (same name as `['Key']`)
- Keys must be unique within a collection
- Reference target collections BEFORE the collections that reference them
- Use tabs for indentation — spaces cause parse errors

```alan
'Products': collection ['Product ID'] {
	'Product ID': text
	'Name': text
	'Price': number 'eurocent'
	'Category': text -> ^ .'Categories'[]
}
```

### Stategroups

States can have their own nested properties:
```alan
'Order status': stategroup (
	'Pending' { }
	'Shipped' {
		'Tracking number': text
		'Ship date': number 'date'
	}
	'Cancelled' {
		'Reason': text
	}
)
```

---

## Numerical Types

Every number needs a unit declared in the `numerical-types` section:

```alan
numerical-types
	'eurocent'
		@numerical-type: (
			label: "Euro"
			decimals: 2
		)
	'units'
	'percent'
	'date' @date: date
	'seconds' @duration: seconds
	'minutes' @duration: minutes
```

**Conversion rules** (for derived value arithmetic):
```alan
numerical-types
	'eurocent'                              // base unit
	'hundreds-of-eurocent'
		'eurocent' = 'hundreds-of-eurocent' * 1 * 10 ^ -2
	'units'
	'total-eurocent'
		'total-eurocent' = 'eurocent' * 'units'  // for product()
```

**CRITICAL decimals bug:** Alan stores integers. `eurocent` with `decimals: 2` means `100` stores as `1.00`. When you multiply two decimal numbers, create a new unit for the result with double the decimals. This prevents the "20 × 5 = 10000" issue.

---

## Derived Values — Expressions

```alan
// Arithmetic
'Total': number 'eurocent' = sum .'Lines'* .'Amount'
'Line total': number 'eurocent' = product ( .'Qty' as 'units' , >'Product'.'Price' )
'Avg': number 'eurocent' = division ( .'Total' as 'eurocent' , .'Count' as 'units' )

// Text
'Label': text = concat ( .'First' , " " , .'Last' )

// Switch on stategroup
'Fee': number 'eurocent' = switch .'Type' (
	|'Premium' => 500
	|'Standard' => 0
)

// Switch with comparison
'Status label': text = switch .'Score' compare ( 50 ) (
	| < => "Fail"
	| >= => "Pass"
)

// Conditional on collection filter
'Has active items': stategroup ( 'Yes' { } 'No' { } ) = switch .'Items'* .'Active'?'Yes' (
	| nodes => 'Yes' ( )
	| none => 'No' ( )
)

// Count with filter
'Active count': number 'units' = count .'Items'* .'Active'?'Yes'
```

---

## Permissions

Permissions are cumulative downward (child needs all ancestor permissions too).

```alan
root {
	can-read: any user             // everyone can read root
	can-update: user               // logged-in users can update root

	'Users': collection ['User'] {
		can-read: user             // must be logged in
		can-update: user == ^      // can only update your own entry

		// Item-level permissions
		can-create: user .'Admin'?'Yes'
		can-delete: user .'Admin'?'Yes'
	}
}
```

**Permission patterns:**
```alan
can-read: any user                          // no auth required
can-read: user                              // any logged-in user
can-read: user .'Admin'?'Yes'               // admin only
can-read: user .'Role'?'Manager'            // specific state
can-update: user == ^                       // only self (in Users collection)
can-read: interface 'SystemName'            // external system access
```

**Multiple conditions** (AND by stacking where):
```alan
can-read: user .'Type'?'A' where ( .'Status'?'Active' )
          user .'Type'?'B' where ( .'Status'?'Active' )
```

---

## Commands and Actions

**Command** (server-side, atomic transaction, used for complex writes):
```alan
'Create order': command {
	'Customer ID': text
	'Items': collection ['Line'] {
		'Line': text
		'Product': text
		'Qty': number 'units'
	}
} as $'params' => update .'Orders' = create (
	'Order ID' = ^ .'Next order ID'          // use derived counter
	'Customer' = $'params'.'Customer ID'
	'Lines' = walk $'params'.'Items'* as $'line' (
		create (
			'Line' = $'line'.'Line'
			'Product' = $'line'.'Product'
			'Qty' = $'line'.'Qty'
		)
	)
)
```

**Action** (client-side, simpler, no server call):
```alan
'Archive': action => update .'Status' = 'Archived' ( )
```

**Switch on user in command** (for auto-assigning current user):
```alan
'Submit': command { 'Notes': text } as $'p' =>
	switch user (
		| node as $'u' => update .'Tasks' = create (
			'Task ID' = ...
			'Assigned to' = $'u'.'Username'
			'Notes' = $'p'.'Notes'
		)
		| none => ignore
	)
```

---

## Users & Authentication

**Anonymous access** (no login required):
```alan
users
	anonymous
```

**Password authentication:**
```alan
users
	dynamic: .'Users'
		passwords: .'Passwords'
			password-value: .'Data'.'Password'
			password-status: .'Data'.'Active' (
				| active => 'Yes' ( )
				| reset => 'No' ( )
			)
		password-initializer: (
			'Data' = ( )
		)
```

In `systems/sessions/config.alan`:
```
password-authentication: enabled
```

In `systems/client/settings.alan`:
```
"anonymous login: disabled"
```

First deploy credentials: username `root`, password `welcome` (forced reset on first login).

---

## UI Annotations

These go on properties and collections (prefix `@`):

```alan
'Name': text @identifying                   // shown in references and compact views
'Price': number 'eurocent' @min: 0 @max: 99999
'Email': text @validate: "[^@]+@[^.]+\..+"
'Notes': text @description: "Internal notes only"
'Count': number 'units' @hidden              // hide derived values from UI
'Items': collection ['ID'] @small { }        // inline display; included in Duplicate
'Type': stategroup ( ... ) @default: 'Active' ( )
'Date': number 'date' @default: now
```

**Performance annotations:**
- `@hidden` — hides property but still queries it when accessed
- `@breakout` — much better: only loads data when that view is opened; prevents data from appearing in compact collection views

---

## Wiring

The `wiring/project.wiring` file wires your systems together:

```
interfaces { }

models
	'model': @'"models/model"'

systems
	'server': @'"systems/server"'
	'client': @'"systems/client"'
	'reporter': @'"systems/reporter"'
	'sessions': @'"systems/sessions"'

provided connections { }
```

---

## Migration Syntax

The `migration.alan` file maps old model properties to new ones:

```alan
root = root as $ (
	'New property': text = $ .'Old property'      // rename
	'Description': text = "Default value"          // set default
	'Year': number = 2024                          // number default
	'Status': stategroup = 'Active' (              // set state
		'Active': $ .'Was active' (
			'Active': 'Yes' ( )
			'Inactive': 'No' ( )
		)
	)
	'Items': collection = map $ .'Old items'* as $'item' (
		'New key' = $'item' .'Old key'
		'Value' = $'item' .'Value'
	)
)
```

Use `Alan: Generate Migration` from the Command Palette to auto-generate a skeleton — then fill in any renamed/restructured properties.

---

## Common Pitfalls and Solutions

**1. "The 20 × 5 = 10000 problem"** — Always define a product result unit with combined decimal scale. Line-level calculation before aggregation.

**2. "Only tabs" rule** — Indentation must use tabs. Spaces cause cryptic parse errors.

**3. Parent navigation depth** — Count `^` carefully. `^ ^ .'Collection'[]` goes up two levels. Draw your node tree.

**4. Referenced collection must be defined before the referencing collection** — The target of `->` must appear earlier in the model.

**5. Permissions are AND-cumulative** — Child needs parent's permission too. A child `can-read: user .'Admin'?'Yes'` on a node whose parent has `can-read: any user` is fine. But if the parent is more restrictive, the child cannot be more permissive.

**6. `@default: user` for auto-assigning users** — Works but user can override. For locked assignment, use a command instead.

**7. Duplicate only copies `@small` collections** — Standard nested collections stay empty on Duplicate.

**8. Dynamic numerical type binding needs `@default:`** — Without a default, decimal input breaks on new entry creation.

**9. Migration must include ALL base properties** — You cannot skip properties even if you want to drop them. Include them, then stop using them.

**10. Keys must be unique** — If you need non-unique "keys" (e.g., for JSON output with duplicate keys), handle serialization in a connector processor, not in the model.

---

## Workflow for Building a New Feature

1. **Design the data first** — Sketch collections, their keys, and relationships
2. **Order collections** — Referenced collections first
3. **Add to application.alan** — Types, references, derived values
4. **Add permissions** — can-read, can-update, can-create, can-delete
5. **Add UI annotations** — @identifying, @hidden, @small, @breakout as needed
6. **Alan Build** — Fix all errors
7. **Generate Migration** — Review the auto-generated migration.alan
8. **Alan Deploy (migrate)** — Deploy and test
9. **Alan Show** — Open and verify in browser

---

## Quick Reference: Expression Keywords

| Expression | Purpose |
|-----------|---------|
| `sum .'Coll'* .'Prop'` | Sum a number across a collection |
| `count .'Coll'*` | Count entries |
| `min / max` | Minimum / maximum |
| `product ( a as 'u1' , b )` | Multiply two numbers |
| `division ( a as 'u' , b as 'u' )` | Divide |
| `diff ( a , b )` | Absolute difference |
| `concat ( a , " " , b )` | Concatenate text |
| `switch .'SG' ( |'S' => ... )` | Branch on stategroup |
| `switch X compare ( Y ) ( | < => ... | >= => ... )` | Numeric comparison |
| `walk .'Coll'* as $'x' ( ... )` | Iterate in commands |
| `create ( ... )` | Create a new collection entry |
| `update .'Prop' = ...` | Update a value |
| `delete` | Delete current entry |
| `ignore` | No-op in switch branch |

---

For more detail on any section, read the reference files in `references/`.
