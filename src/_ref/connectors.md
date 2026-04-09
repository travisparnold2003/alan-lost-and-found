# Alan Connectors & Interfaces

Connectors bridge Alan applications with external systems — REST APIs, databases, email, file imports, webhooks, etc.

---

## Connector Types

| Type | Use case |
|------|----------|
| **Scheduled provider** | Pull data from external API on a schedule |
| **Consumer** | React to model changes, push data out |
| **Library** | Expose hooks for external triggers (webhooks) |

---

## Connector Processor Syntax (processor.alan)

### Scheduled Provider
```
provider scheduled
	dataset: from main routine
	main routine
	do {
		// build and yield dataset snapshot
		yield (
			'Items': {
				'item-1': (
					'Name': "First item"
					'Value': 42
				)
			}
		)
	}
	command handlers { }
```

### Consumer (reacts to model changes)
```
consumer
	on entry creation .'Collection'* do {
		// $'entry' is the new entry
		// Execute side effects: HTTP calls, email, etc.
	}

	on entry deletion .'Collection'* do {
		// cleanup
	}

	on node update .'Collection'*.'Property' do {
		// react to specific property change
	}
```

### Library (webhook receiver)
```
library
	hook 'network'::'webserver'
```

---

## Standard Libraries Available in Processor

### Network
```
// HTTP request
let $'response' = call 'network'::'http' with (
	$'url' = "https://api.example.com/endpoint"
	$'method' = "POST"
	$'headers' = {
		"Content-Type": "application/json"
		"Authorization": concat ( "Bearer " , $'api-key' )
	}
	$'body' = serialize as JSON {
		'field': "value"
	}
)
let $'body' = $'response'.'body' get || throw "No response body"
let $'text' = $'body' => call 'unicode'::'import' with ( $'encoding' = "UTF-8" )
let $'data' = $'text' => parse as JSON
```

### Webserver (webhook)
```
add-hook 'network'::'webserver' "/webhook-path"
do {
	// $'request' is the incoming HTTP request
	let $'method' = $'request'.'method'
	let $'content-opt' = $'request'.'content'
	let $'content' = $'content-opt' get || throw "Missing body"
	let $'text' = $'content' => call 'unicode'::'import' with ( $'encoding' = "UTF-8" )
	let $'json' = $'text' => parse as JSON

	// Access collection and execute command
	switch ^ $'Collection'[$'key-value'] (
		| value as $'entry' => {
			execute $'entry'::'Command' with (
				'Field' = $'json'.'field' get || throw "Missing field"
			)
			$ = success "OK"
		}
		| error => $ = failure "Not found"
	)
}
```

### Unicode (text encoding)
```
// Binary → text
let $'text' = $'binary' => call 'unicode'::'import' with ( $'encoding' = "UTF-8" )

// Text → binary
let $'binary' = "hello" => call 'unicode'::'export' with ( $'encoding' = "UTF-8" )

// String manipulation
let $'upper' = call 'unicode'::'to upper case' with ( $'text' = $'input' )
let $'trimmed' = call 'unicode'::'trim' with ( $'text' = $'input' )
```

### Calendar (date/time)
```
let $'now' = call 'calendar'::'now'
let $'today' = call 'calendar'::'today'
let $'date' = call 'calendar'::'date' with (
	$'year' = 2024
	$'month' = 12
	$'day' = 25
)
```

### Plural (set operations)
```
let $'sorted' = call 'plural'::'sort' with (
	$'list' = $'items'
	$'key' = $'item' => $'item'.'priority'
)

let $'filtered' = call 'plural'::'filter' with (
	$'list' = $'items'
	$'condition' = $'item' => $'item'.'active'
)

let $'first' = call 'plural'::'first' with ( $'list' = $'items' ) get || throw "Empty"
```

### Data (encoding)
```
let $'base64' = call 'data'::'base64 encode' with ( $'binary' = $'data' )
let $'decoded' = call 'data'::'base64 decode' with ( $'text' = $'base64' )
```

---

## Key Processor Patterns

### Promise / Optional Pattern
When a value might not exist, use `get` with fallback:
```
let $'value' = $'optional-thing' get || throw "Value was missing"
let $'value' = $'optional-thing' get || "default value"
```

### Let blocks (immutable variables)
```
let $'name' = "value"
let $'result' = call 'library'::'function' with ( $'arg' = $'value' )
```

### Walk (iterate and collect)
```
let $'results' as list = walk $'collection' as $'item' (
	// transform $'item' and yield
	$ = call 'some'::'function' with ( $'input' = $'item'.'field' )
)
```

### Multiple HTTP requests (walk then join)
```
// CORRECT: walk first, collect results, then join
let $'names' as list = walk $'items' as $'item' (
	let $'resp' = call 'network'::'http' with (
		$'url' = concat ( "https://api.example.com/items/" , $'item'.'id' )
		$'method' = "GET"
	)
	let $'data' = $'resp'.'body' get
		=> call 'unicode'::'import' with ( $'encoding' = "UTF-8" )
		=> parse as JSON
	$ = $'data'.'name' get || "unknown"
)
'Combined names': text = join ( $'names' with separator: ", " )

// WRONG: calling HTTP inside join() — fails with type error
```

### JSON serialization
```
// Build JSON object
let $'payload' = serialize as JSON {
	'key': "value"
	'number': 42
	'nested': {
		'inner': "data"
	}
	'array': [ "a" , "b" , "c" ]
}

// Walk collection into JSON array
let $'items-json' as list = walk $'items' as $'item' (
	$ = serialize as JSON {
		'type': $'item'.'type'
		'text': $'item'.'value'
	}
)
```

### Guard / try-catch
```
try {
	// risky operation
	let $'result' = call 'network'::'http' with ( ... )
	// success path
} catch {
	// error path — $'error' available
	$ = failure $'error'
}
```

---

## Variables File (variables.alan)

Store configuration that changes per environment:
```
'API key': text = "your-api-key-here"
'Base URL': text = "https://api.example.com"
'Timeout': number = 30000
```

Access in processor:
```
let $'key' = ^ $'API key'
let $'url' = ^ $'Base URL'
```

---

## Interface Definition

For two Alan systems to communicate:

```alan
// interfaces/my-api/interface.alan
root {
	'Products': collection ['SKU'] {
		'SKU': text
		'Name': text
		'Price': number 'eurocent'
	}

	'Sync product': command {
		'SKU': text
		'New price': number 'eurocent'
	}

	'Price updated': event {
		'SKU': text
		'Old price': number 'eurocent'
		'New price': number 'eurocent'
	}
}

numerical-types
	'eurocent'
```

Declare in wiring and map in the consuming system's datastore config.

---

## Connector in Wiring

```
systems
	'my-connector': @'"systems/my-connector"'
		mapping (
			'model': @'model'
		)
		consuming (
			'external-api': @'external-api-system'
		)
```
