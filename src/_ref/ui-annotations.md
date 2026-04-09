# Alan UI Annotations & Auto-Webclient

The auto-webclient generates the full web UI from your model. You control its appearance with annotations.

---

## Property Annotations

Apply on any property with `@` prefix:

```alan
// Identification
'Name': text @identifying          // shown in reference dropdowns and compact view
'Code': text @identifying          // multiple @identifying = combined display

// Visibility
'Internal note': text @hidden      // hidden in UI (still queried when accessed)
'Details': group @breakout {       // only loaded/shown when section is expanded
	'Long description': text
	'Technical specs': text
}

// Input validation
'Email': text @validate: "[^@]+@[^.]+\..+"
'Code': text @validate: "[A-Z]{2}[0-9]{4}"

// Numeric constraints
'Price': number 'eurocent' @min: 0 @max: 999999
'Discount': number 'percent' @min: 0 @max: 100

// Default values
'Status': stategroup ( ... ) @default: 'Active' ( )
'Date': number 'date' @default: now
'Owner': text -> ^ .'Users'[] @default: user    // default to current user
'Count': number 'units' @default: 0

// Labels and help text
'Notes': text @description: "Internal use only — not shown to customers"

// File display
'Image': file @image                            // render as image inline
'Document': file @download                      // show as download link

// Icons (uses Material Design icon names)
'Status': stategroup (
	'Active' @icon: "check_circle" { }
	'Inactive' @icon: "cancel" { }
)
```

---

## Collection Annotations

```alan
'Items': collection ['ID'] @small {             // inline display; included in Duplicate
	'ID': text
	'Value': number 'units'
}

'Orders': collection ['Order ID'] @breakout {   // only loads when section is opened
	// ...
}

'History': collection ['Event'] @hidden {       // hidden collection (still queryable)
	// ...
}
```

---

## Client Settings (systems/client/settings.alan)

Full configuration for the auto-webclient generator:

```
"application creator": "Kjerner"
"application name": "My ERP System"
"allow anonymous user": disabled        // enabled or disabled
"enable csv actions": enabled           // adds CSV import/export buttons to collections
"report limit": 10000                   // max rows in Excel reports
"announcement title": "Welcome"
"language": "en"                        // UI language
"engine language": english              // sort/date/number engine: english or dutch

// Theme (optional)
"theme": (
	"foreground": "#202124"
	"background": "#ffffff"
	"brand": "#1a73e8"
	"link": "#1a73e8"
	"accent": "#fbbc04"
	"success": "#34a853"
	"warning": "#fbbc04"
	"error": "#ea4335"
)

// Landing page (optional)
"has landing page": enabled (
	"landing page selector": ...
)
```

---

## Generator Annotations (auto-webclient advanced)

For handheld/mobile views and advanced desktop features, use generator annotations in the application model:

```alan
// In application.alan, alongside property definitions:
'Items': collection ['ID'] {
	'ID': text
	'Name': text @identifying
	'Status': stategroup (
		'Active' { }
		'Inactive' { }
	)
}

// Separate annotations file or inline:
// @generator-annotation: (
//   collection-layout: cards         // tabular | cards | buttons | partition
//   sort-by: .'Name'
//   filter: .'Status'?'Active'
// )
```

The generator annotations enable:
- **Handheld views:** decision trees, barcode scanning (`@barcode`), pivot tables, card layouts
- **Planning boards:** Gantt-style planning widgets
- **Dashboard widgets:** summary panels
- **Custom command button placement**

---

## CSV Import/Export

When `"enable csv actions": enabled`:

**Export:** Two buttons per collection — Excel (`.xlsx`, includes derived data) and CSV (base data only).

**Import CSV format:**
- Column 1: item key (must match collection key, must be unique)
- Column 2: operation — `add`, `update`, or `remove`
- Remaining columns: property values in order
- Stategroups: `update` or `set` to change state
- Numbers: must match the app's number input format

The exported CSV shows the exact structure needed for import.

---

## Excel Reports (reporter system)

The reporter system generates `.xlsx` files with multiple sheets. Define reports in the reporter system config:

```
// systems/reporter/reports.alan (structure varies by reporter version)
'Monthly summary': report {
	// columns, grouping, filters defined here
}
```

The auto-webclient adds a "Download Excel" button based on reporter configuration.

---

## View Customization (webclient views)

For the custom webclient (`systems/client/views/`), you can define custom views:

```alan
// views/my-collection-view.view (simplified)
view 'my collection view' {
	node type: .'Collection' entry

	queries {
		'main query' {
			context: current node
			limit: 100
		}
	}

	instance: widget 'table' [
		// column definitions
	]
}
```

Custom views give more control than the auto-generated ones but require more work.

---

## Performance Annotations Summary

| Annotation | Effect | Query behavior |
|-----------|--------|----------------|
| *(none)* | Shown everywhere | Always loaded |
| `@hidden` | Hidden in UI | Still queried, loaded when accessed |
| `@breakout` | Only shown when section expanded | Only queried when expanded — best performance |
| `@small` | Inline in parent; included in Duplicate | Always loaded (small collections only) |

Use `@breakout` liberally on large groups and collections that users rarely need to see immediately. It significantly improves initial load time and rendering performance for large models.
