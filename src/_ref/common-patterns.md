# Alan Common Patterns & Forum Solutions

Proven solutions from the Alan forum and real projects. Reference this when stuck on specific problems.

---

## Decimal Arithmetic — The "10000 Bug"

**Problem:** `20 × 5 = 10000` instead of `100.00`

Alan stores integers. `eurocent` with `decimals: 2` means the DB stores `100` to represent `1.00`. When you multiply `2000 (=20.00) × 500 (=5.00)` you get `1,000,000` — the client then shows `10000.00`.

**Solution:** Define a result unit with combined decimal places:

```alan
numerical-types
	'eurocent'
		@numerical-type: ( label: "Euro" decimals: 2 )
	'units'
		@numerical-type: ( label: "" decimals: 0 )
	'eurocent-result'                                      // 0 + 2 = 2 decimals total
		'eurocent' = 'eurocent' * 'units' * 1             // product rule
		@numerical-type: ( label: "Euro" decimals: 2 )

// In model:
'Line total': number 'eurocent-result' = product (
	.'Quantity' as 'units' ,
	>'Product'.'Price'
)
```

For percent × eurocent:
```alan
'percent'
	@numerical-type: ( label: "%" decimals: 2 )
'eurocent-x-percent'                        // 2 + 2 = 4 decimals, then scale back by 10^-2
	'eurocent' = 'eurocent' * 'percent' * 10 ^ -2
	@numerical-type: ( label: "Euro" decimals: 2 )
```

**Rule:** Do multiplication PER LINE first, then aggregate with `sum`. Never aggregate first then multiply.

---

## Auto-Assign Current User

**With @default (user can override):**
```alan
'Created by': text -> ^ .'Users'[] @default: user
```

**Locked (use a command):**
```alan
'Submit': command { 'Title': text } as $'p' =>
	switch user (
		| node as $'u' => update .'Tasks' = create (
			'Task ID' = ^ .'Next ID'
			'Title' = $'p'.'Title'
			'Owner' = $'u'.'Username'
		)
		| none => ignore
	)
```

---

## Time / Hour-Minute Selector

**Using duration type (preferred, enables calculations):**
```alan
'Start time': number positive 'seconds' @min: 0 @max: 86399
	// displays as HH:MM:SS in UI
'Start minute': number positive 'minutes' @min: 0 @max: 1439
	// displays as HH:MM

numerical-types
	'seconds' @duration: seconds
	'minutes' @duration: minutes
```

**Using stategroup (no calculations possible):**
```alan
'Hour': stategroup (
	'00' { } '01' { } '02' { } '03' { } '04' { }
	'05' { } '06' { } '07' { } '08' { } '09' { }
	'10' { } '11' { } '12' { } '13' { } '14' { }
	'15' { } '16' { } '17' { } '18' { } '19' { }
	'20' { } '21' { } '22' { } '23' { }
)
```

Note: Date/time values are stored in UTC, displayed in user's local timezone.

---

## Permissions — Complex Patterns

**AND conditions (stack where clauses):**
```alan
can-read: user .'Type'?'Manager' where ( .'Department' == ^ .'Department' )
          user .'Type'?'Admin'
```

**Role-based record access:**
```alan
'Records': collection ['ID'] {
	can-read: user .'Role'?'Type A' where ( .'Status'?'Type A status' )
	          user .'Role'?'Type B' where ( .'Status'?'Type B status' )
}
```

**Self-only update:**
```alan
'Users': collection ['User'] {
	can-update: user == ^      // only update your own entry
}
```

**Admin or self:**
```alan
can-update: user .'Admin'?'Yes'
            user == ^
```

---

## Stategroup Based on Collection Existence

**Does a filtered collection have any entries?**
```alan
// Elegant approach — filter then check nodes/none
'Has certified items': stategroup ( 'Yes' { } 'No' { } ) =
	switch .'Certifications'* .'Valid'?'Yes' .'Certified'?'Yes' (
		| nodes => 'Yes' ( )
		| none => 'No' ( )
	)

// Count-based approach
'Cert count': number 'units' = count .'Certifications'* .'Valid'?'Yes'
'Is certified': stategroup ( 'Yes' { } 'No' { } ) =
	switch .'Cert count' compare ( 0 ) (
		| > => 'Yes' ( )
		| <= => 'No' ( )
	)
```

---

## Copying Nodes (Duplicate)

The built-in "Duplicate" button copies a node but leaves nested collections EMPTY by default.

To include a nested collection in Duplicate, mark it `@small`:
```alan
'Variants': collection ['Variant'] @small {
	'Variant': text
	'Color': text
	'Price delta': number 'eurocent'
}
```

Only use `@small` for collections expected to have few entries (< ~20 items). It also renders them inline.

---

## Non-Unique Keys in JSON Output (Connector Pattern)

Alan enforces unique keys in collections — you can't model duplicate JSON keys directly.

**Solution:** Use a unique key (like index) in the model, and serialize to desired JSON in the processor:
```
// In interface: use unique key
'Parameters': collection ['Index'] {
	'Index': text
	'Type': text
	'Value': text
}

// In processor.alan: walk and build JSON with any structure
let $'json-params' as list = walk $'params' as $'p' (
	serialize as JSON { 'type': $'p'.'Type' , 'text': $'p'.'Value' }
)
```

---

## Webhook / HTTP Callback Pattern

Minimal webhook receiver setup in a connector consumer:

```
// In processor.alan
add-hook 'network'::'webserver' "/callback"
do {
	let $'content' = $'request'.'content' get || throw "Missing body"
	let $'text' = $'content'
		=> call 'unicode'::'import' with ( $'encoding' = "UTF-8" )
		=> parse as JSON

	switch ^ $'Collection'[$'key-value'] (
		| value as $'entry' => {
			execute $'entry'::'Command' with (
				'Field' = $'text'.'field' get || throw "Missing field"
			)
			$ = success "OK"
		}
		| error => $ = failure "Not found"
	)
}
```

Key rules:
- `request.content` is optional binary — always use `get || throw`
- Chain `=> call 'unicode'::'import'` to convert binary to text
- Then `=> parse as JSON` to get structured data
- Use `switch collection[key]` with `value as $` / `error` branches

---

## Multiple HTTP Requests in Connector

**Wrong way:** trying to call HTTP inside `join` — fails with type error.

**Right way:** walk first, collect results, then join:
```
let $'author-names' as list = walk $'book'.'authors' as $'author' (
	let $'response' = call 'network'::'http' with (
		$'url' = concat ( "https://openlibrary.org/authors/" , $'author'.'key' , ".json" )
		$'method' = "GET"
	)
	let $'body' = $'response'.'body' get || throw "No body"
		=> call 'unicode'::'import' with ( $'encoding' = "UTF-8" )
		=> parse as JSON
	$ = $'body'.'name' get || "Unknown"
)
'Authors': text = join ( $'author-names' with separator: ", " )
```

---

## Migration: Keeping Existing Data

You cannot "skip" migration for unchanged data. The source model in `from/` must exactly match the deployed dataset.

**Pattern for complex transforms** — add derived properties to the source model temporarily, then migrate from those derived values:
1. Deploy with the derived property added to the OLD model
2. Generate migration from that extended old model
3. Map from the derived property
4. Deploy

---

## Reference Sets — Bidirectional Aggregation

```alan
// In 'Customers' collection:
'All orders': reference-set -> downstream ^ .'Orders'* .'Customer' = inverse >'Customer'
'Order count': number 'units' = count <'All orders'*
'Total revenue': number 'eurocent' = sum <'All orders'* ^ .'Total'

// In 'Orders' collection:
'Customer': text -> ^ .'Customers'[]
```

**Union on reference set with acyclic graph:**
```alan
'Sub-parties': collection ['Party'] = union (
	'In party' = >'Party' ^ ^ ^ ^ ^ <'Sub-parties'[ >'Party' ^ ^ ^ ^ ^ sibling * ]
) { ... }
```

---

## Performance Tips

- Large models → slow initial load; consider splitting
- `@breakout` on collections and groups: **only loads when that section is viewed** — best performance annotation; prevents data from appearing in compact table views
- `@hidden`: hides property visually but still queries it when needed
- More properties on collection entries → larger table views
- Use `@small` sparingly — it makes collections inline and included in Duplicate
- Minimize flattened/union derived collections where possible
