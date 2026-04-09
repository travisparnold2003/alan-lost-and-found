# Alan Application Language — Full Reference

## Minimal Valid Model

```alan
users
	anonymous

interfaces

root { }

numerical-types
```

---

## Users Section

### Anonymous (no authentication)
```alan
users
	anonymous
```

### Password authentication
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

### Both anonymous and authenticated
```alan
users
	anonymous
	dynamic: .'Users'
		passwords: .'Passwords' ...
```

### OAuth / external authority
Configure via `authorities` system in wiring. Reference the platform docs for the specific OAuth provider setup.

---

## Property Types

### Text
```alan
'Name': text
'Code': text @validate: "[A-Z]{2}[0-9]{4}"
```

### Number
```alan
'Price': number 'eurocent'
'Count': number positive 'units'          // positive constrains to >= 0
'Balance': number 'eurocent' @min: -10000 @max: 10000
```

### File
```alan
'Attachment': file
```

### Collection
```alan
'Products': collection ['SKU'] {
	'SKU': text
	'Name': text
	'Stock': number 'units'
}
```

With graph constraint (for trees / ordered lists):
```alan
'Categories': collection ['Category'] acyclic-graph {
	'Category': text
	'Parent': text -> ^ sibling?
}

'Tasks': collection ['Task'] ordered-graph {
	'Task': text
	// auto-gets 'forward' and 'backward' virtual edges
}
```

### Stategroup
```alan
'Status': stategroup (
	'Draft' { }
	'Active' {
		'Activated on': number 'date'
	}
	'Archived' {
		'Archive reason': text
	}
)
```

### Group
```alan
'Contact info': group {
	'Email': text
	'Phone': text
}
```

---

## Derived Value Expressions

### Derived text
```alan
'Display name': text = concat ( .'First name' , " " , .'Last name' )
'Static label': text = "Hello"
'Key reference': text = > 'Category' key   // text value of referenced key
```

### Derived numbers
```alan
// Aggregation over collection
'Total value': number 'eurocent' = sum .'Order lines'* .'Line total'
'Item count': number 'units' = count .'Items'*
'Lowest price': number 'eurocent' = min .'Products'* .'Price'
'Highest price': number 'eurocent' = max .'Products'* .'Price'

// With filter
'Active count': number 'units' = count .'Items'* .'Status'?'Active'
'Active total': number 'eurocent' = sum .'Items'* .'Status'?'Active' .'Value'

// Arithmetic
'Line total': number 'eurocent' = product ( .'Quantity' as 'units' , >'Product'.'Price' )
'Tax amount': number 'eurocent' = product ( .'Subtotal' as 'eurocent' , ^ .'Tax rate' as 'percent' )
'Ratio': number 'percent' = division ( .'Numerator' as 'numerator-unit' , .'Denominator' as 'denominator-unit' )
'Diff': number 'eurocent' = diff ( .'Budget' , .'Actual' )

// Addition (not sum — for exactly two values)
'Combined': number 'eurocent' = add ( .'Base' , .'Surcharge' )

// From conversion
'In cents': number 'cents' = from 'hundreds-of-cents' .'Wholesale price'
```

### Derived stategroup
```alan
// Switch on stategroup
'Is premium': stategroup ( 'Yes' { } 'No' { } ) = switch .'Tier' (
	|'Gold' => 'Yes' ( )
	|'Silver' => 'No' ( )
	|'Bronze' => 'No' ( )
)

// Switch on collection filter (nodes/none pattern)
'Has items': stategroup ( 'Yes' { } 'No' { } ) = switch .'Items'* (
	| nodes => 'Yes' ( )
	| none => 'No' ( )
)

// Switch with filter
'Has active': stategroup ( 'Yes' { } 'No' { } ) = switch .'Items'* .'Status'?'Active' (
	| nodes => 'Yes' ( )
	| none => 'No' ( )
)
```

### Derived reference (text that references a collection)
```alan
'Default supplier': text = >'Category'.'Default supplier'
```

### Derived collection (union / flatten)
```alan
// Flatten nested collections
'All lines': collection ['Line ID'] = flatten .'Orders'* .'Lines'*

// Union from multiple reference sets
'All related': collection ['Item'] = union (
	'Direct' = .'Direct items'*
	'Indirect' = <'Indirect refs'*
)
```

---

## Reference Patterns

### Navigation cheat sheet
```
.'Prop'                → property on current node
?'State'               → enter a stategroup state
>'Ref'                 → follow reference to target node
^                      → parent node
^^                     → grandparent node
$ or $'name'           → named variable
user                   → current authenticated user node
<'RefSet'              → follow reference set (inverse)
```

### Reference with variable
```alan
'Product': text -> ^ .'Products'[] as $'p'
	where 'in stock' -> $'p'.'Stock'?'Available'
	where 'in category' -> $'p'.'Category' == ^ .'Target category'
```

### Reference set (bidirectional)
```alan
// In the "parent" collection:
'Order refs': reference-set -> downstream ^ .'Orders'* .'Customer' = inverse >'Customer'

// Aggregate via reference set:
'Order count': number 'units' = count <'Order refs'*
'Total spent': number 'eurocent' = sum <'Order refs'* ^ .'Total'
```

### Sibling reference (for trees)
```alan
'Parent category': text -> ^ sibling?        // optional sibling
'Next item': text -> ^ sibling               // mandatory sibling
```

---

## Timers

```alan
'Expires at': number 'milliseconds'
'Expiry timer': timer ontimeout .'Expires at' => update .'Status' = 'Expired' ( )
```

---

## Numerical Types — Full Syntax

```alan
numerical-types
	// Simple unit (integer storage)
	'units'

	// With UI formatting
	'eurocent'
		@numerical-type: (
			label: "Euro"
			decimals: 2
		)

	// Date (stored as days since epoch)
	'date' @date: date

	// Date-time
	'milliseconds' @date: date-time

	// Duration
	'seconds' @duration: seconds
	'minutes' @duration: minutes
	'hours' @duration: hours
	'days' @duration: days

	// Conversion: defines product/division rules
	'percent'
		@numerical-type: ( label: "%" decimals: 2 )
	'eurocent-percent'                                  // result type for eurocent * percent
		'eurocent' = 'eurocent' * 'percent' * 10 ^ -2  // scale factor
		@numerical-type: ( label: "Euro" decimals: 4 )  // 4 decimals for precision

	// Bound to user-defined label + decimals
	'amount'
		@bind: ( label: >'Unit'.'Label' decimals: >'Unit'.'Decimals' )
```

---

## Full Example: E-commerce Model Skeleton

```alan
users
	anonymous

interfaces

root {
	can-read: any user
	can-update: user .'Admin'?'Yes'

	'Settings': group {
		'Tax rate': number 'percent' @min: 0 @max: 100
	}

	'Categories': collection ['Category'] {
		'Category': text
		'Description': text
	}

	'Products': collection ['SKU'] {
		'SKU': text
		'Name': text @identifying
		'Category': text -> ^ .'Categories'[]
		'Price': number 'eurocent' @min: 0
		'Stock': number 'units' @min: 0
		'Active': stategroup (
			'Yes' { }
			'No' { }
		)
	}

	'Orders': collection ['Order ID'] {
		'Order ID': text
		'Date': number 'date'
		'Lines': collection ['Line'] {
			'Line': text
			'Product': text -> ^ ^ .'Products'[]
			'Quantity': number 'units' @min: 1
			'Unit price': number 'eurocent' = >'Product'.'Price'
			'Line total': number 'eurocent' = product (
				.'Quantity' as 'units' ,
				.'Unit price'
			)
		}
		'Subtotal': number 'eurocent' = sum .'Lines'* .'Line total'
		'Tax': number 'eurocent' = product (
			.'Subtotal' as 'eurocent' ,
			^ .'Settings'.'Tax rate' as 'percent'
		)
		'Total': number 'eurocent' = add ( .'Subtotal' , .'Tax' )
	}
}

numerical-types
	'eurocent'
		@numerical-type: ( label: "Euro" decimals: 2 )
	'units'
	'percent'
		@numerical-type: ( label: "%" decimals: 2 )
	'date' @date: date
```
