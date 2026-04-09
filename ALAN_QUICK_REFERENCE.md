# Alan Platform Quick Reference Guide

## 📐 BASIC SYNTAX

### Collections
```alan
'CollectionName': collection ['Primary Key'] {
    'FieldName': type @options
}
```

### References
```alan
'RelatedItem': reference 'OtherCollection' @description: 'Description'
```

### Reference Sets
```alan
'RelatedItems': reference set 'OtherCollection'::'referenceField'
```

### Groups
```alan
'GroupName': group {
    'SubField': type
}
```

### Derived Fields
```alan
'DerivedName': derived stategroup (
    'SourceField' of (
        'Value1': 'Result1'
        'Value2': 'Result2'
    )
)
```

### Stategroups (Enums)
```alan
'Status': stategroup (
    'Value1' { }
    'Value2' { }
)
```

### Numbers with Units
```alan
'DaysField': number 'days' @min: 1 @max: 365
```

### Time Fields
```alan
'Timestamp': time @default: now
```

### File Fields
```alan
'Attachment': file @description: 'File attachment'
```

## 🏷️ ESSENTIAL ANNOTATIONS

| Annotation | Usage | Example |
|------------|-------|---------|
| `@identifying` | Natural key / business ID | `'UserID': text @identifying` |
| `@validate: email` | Email validation | `'Email': text @validate: email` |
| `@description` | Field/documentation | `'Name': text @description: 'Full name'` |
| `@default` | Default value | `'Created': time @default: now` |
| `@min`/@`max` | Numeric bounds | `'Age': number @min: 0 @max: 150` |
| `@breakout` | Dashboard UI enhancement | `'Stats': group @breakout { ... }` |

## 🔐 AUTHENTICATION PATTERN

### sessions/config.alan
```alan
password-authentication: enabled
allow-user-creation: enabled
```

### Model Initializer (in Users/Passwords)
```alan
'Passwords': collection ['User'] {
    'Password': text @description: 'Hashed password'
    'Active': stategroup (
        'Yes' { }
        'No'  { }
    )
    'password-initializer': (
        'Data' = (
            'User': text = "root"
            'Role': stategroup = 'Administrator' ( )
            'Staff Member': reference = <!""!> ( )
        )
    )
}
```

## 🔄 MIGRATION PATTERNS

### First Deployment (with sample data)
```alan
root = root as $ (
    'Locations': collection = <! !> (
        = (
            'Location ID': text = "LOC001"
            'Name': text = "Sample Location"
            // ... other fields
        )
    )
    'Categories': collection = <! !> (
        = (
            'Category ID': text = "CAT001"
            'Name': text = "Sample Category"
            // ... other fields
        )
    )
    // ALL OTHER COLLECTIONS EMPTY
    'Staff': collection = <! !> ( )
    'Users': collection = <! !> ( )
    // etc.
)
```

### Updates/Preserve Data
```alan
root = root as $ (
    'Locations': collection = <! !> ( )
    'Categories': collection = <! !> ( )
    // ALL COLLECTIONS EMPTY FOR PRESERVATION
    'Staff': collection = <! !> ( )
    'Users': collection = <! !> ( )
    // etc.
)
```

## ⚙️ SYSTEM WIRING PATTERN

### wiring/wiring.alan
```alan
interfaces

models
    'model'

external-systems

systems
    'server': 'datastore'
        project / (
            'interfaces' / (
                'providing' / ( )
                'consuming' / ( )
            )
            'model' = provide 'model'
        )

    'sessions': 'session-manager'
        project / (
            'model' = bind 'server'::'authenticate'
        )

    'client': 'auto-webclient'
        project / (
            'model' = consume 'server'/'model'
        )

provided-connections
    'auth' = 'sessions'::'http'
    'client' = 'client'::'http'
```

## 👥 STAFF PRODUCTIVITY TRACKING

### In Staff Collection
```alan
'Staff': collection ['Staff ID'] {
    // ... standard fields
    
    'Logged Item Refs': reference set 'Found Items'::'Logged By'
    'Items Logged Count': count of 'Logged Item Refs'
    'Proposed Match Refs': reference set 'Matches'::'Proposed By'
    'Matches Proposed Count': count of 'Proposed Match Refs'
}
```

## 📊 DASHBOARD PATTERN

### Dashboard Group
```alan
'Dashboard': group @breakout @description: 'Dashboard description' {
    'Metric1': count @description: 'Description of metric 1'
    'Metric2': count @description: 'Description of metric 2'
    // ... add more metrics as needed
}
```

## 🌐 PUBLIC ACCESS SETTINGS

### systems/client/settings.alan
```alan
anonymous login: enabled
name: "Application Display Name"
```

## 💡 COMMON MISTAKES TO AVOID

### ❌ Migration Errors
- Forgetting `<! !> ` before collections in migrations
- Not making ALL collections empty in `from_release` migrations
- Using wrong migration direction (`from_empty` vs `from_release`)

### ❌ Modeling Errors
- Missing `@identifying` on natural keys
- Incorrect password-initializer syntax (wrong nesting)
- Forgetting `@validate: email` on email fields
- Using wrong time syntax (`time` vs `timestamp`)

### ❌ System Errors
- Wrong order in system wiring
- Missing `provided-connections` section
- Not enabling both password auth AND user creation

### ❌ Deployment Errors
- Using `from_release` for initial deploy (loses sample data)
- Not waiting for "0 errors, 0 warnings" before deploying
- Forgetting to commit/push before pulling in IDE

## 🚀 QUICK DEPLOYMENT CHECKLIST

1. [ ] Edit files locally in `src/`
2. [ ] `git commit -m "Description of changes"`
3. [ ] `git push`
4. [ ] In Alan IDE: Pull latest changes
5. [ ] Run `alan build` (ignore IDE validation errors if deploy works)
6. [ ] For FIRST DEPLOY: Select `from_empty` migration
7. [ ] For UPDATES: Select `from_release` migration
8. [ ] Run `alan deploy` with "migrate" option
9. [ ] Verify at: https://app.alan-platform.com/[username]/client/
10. [ ] Check Locations/Categories for sample data
11. [ ] Test login with root/welcome credentials

## 📞 WHERE TO FIND THINGS

- **Data Model**: `src/models/model/application.alan`
- **Sample Data**: `src/migrations/from_empty/to/migration.alan`
- **Auth Config**: `src/systems/sessions/config.alan`
- **Client Settings**: `src/systems/client/settings.alan`
- **System Wiring**: `src/wiring/wiring.alan`
- **Deployment Guide**: `BUILD_STATUS.md`
- **MCP Rules**: `CLAUDE.md`
- **Lessons Learned**: `PROJECT_OVERVIEW_AND_LESSONS_LEARNED.md`

---

*Keep this guide handy for quick reference when working on Alan platform projects.*