# Alan Lost & Found Application

A complete lost and found system built on the Alan platform for Schiphol Airport, implementing all 5 phases of development.

## 📋 Overview

This application provides a comprehensive lost and found system featuring:
- User authentication with role-based access control
- Public interfaces for logging found items and filing loss reports
- Staff matching system to connect found items with loss reports
- Dashboard with live statistics and analytics
- Staff productivity tracking and reference sets
- Mobile-responsive web interface

## 🏗️ Architecture

The application follows Alan platform best practices with:
- **Data Model**: Complete entity relationships in `src/models/model/application.alan`
- **Migrations**: Sample data for initial deployment in `src/migrations/from_empty/`
- **Systems Configuration**: Authentication, client settings, and session management
- **Wiring**: Proper system interconnections in `src/wiring/wiring.alan`

## 🚀 Getting Started

### Prerequisites
- Alan Platform installed and configured
- Git for version control
- Access to Alan IDE at https://ide.alan-platform.com/

### Installation & Deployment

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd alan-project
   ```

2. **Review Code**
   - Examine `src/models/model/application.alan` for the complete data model
   - Check migration files in `src/migrations/` for sample data
   - Verify system configurations in `src/systems/` and `src/wiring/`

3. **Local Development**
   - Make changes to files in the `src/` directory
   - Commit changes: `git commit -m "Description of changes"`
   - Push to remote: `git push`

4. **Deployment to Alan Platform**
   - Pull latest changes in Alan IDE
   - Run `alan build` (ignore IDE validation errors if deployment works)
   - For **initial deployment**: Use `from_empty` migration (includes sample data)
   - For **updates**: Use `from_release` migration (preserves existing data)
   - Run `alan deploy` with "migrate" option
   - Verify deployment at: https://app.alan-platform.com/[your-username]/client/

### Default Credentials
After initial deployment:
- **Username**: `root`
- **Password**: `welcome`

## 📁 Project Structure

```
alan-project/
├── src/
│   ├── models/
│   │   └── model/
│   │       └── application.alan          # Complete 5-phase data model
│   ├── migrations/
│   │   ├── from_empty/
│   │   │   ├── from/
│   │   │   └── to/
│   │   │       └── migration.alan        # Sample Locations & Categories
│   │   └── from_release/
│   │       ├── from/
│   │   │   └── migration.alan            # Empty collections (preserve data)
│   │       └── to/
│   │           └── migration.alan
│   ├── systems/
│   │   ├── client/
│   │   │   └── settings.alan             # Anonymous login, app name
│   │   └── sessions/
│   │       └── config.alan               # Password auth, user creation
│   └── wiring/
│       └── wiring.alan                   # System interconnections
├── BUILD_STATUS.md                       # Deployment status & history
├── CLAUDE.md                             # MCP usage rules
├── CONTEXT.md                            # Workspace context
├── PROJECT_OVERVIEW_AND_LESSONS_LEARNED.md # Detailed state & lessons
├── ALAN_QUICK_REFERENCE.md               # Syntax reference guide
└── README.md                             # This file
```

## 🧪 Testing & Verification

After deployment, verify:
1. ✅ Application loads at the correct URL
2. ✅ Locations section shows sample data (3+ locations)
3. ✅ Categories section shows sample data (3+ categories with correct properties)
4. ✅ Can log in with `root`/`welcome` credentials
5. ✅ Anonymous access works for public features
6. ✅ Staff can propose matches between found items and loss reports
7. ✅ Supervisors can confirm/reject matches with ID verification
8. ✅ Dashboard shows live updating statistics
9. ✅ Staff productivity tracking works correctly

## 📚 Documentation

- **[PROJECT_OVERVIEW_AND_LESSONS_LEARNED.md](PROJECT_OVERVIEW_AND_LESSONS_LEARNED.md)** - Comprehensive review of current state, issues, and lessons learned
- **[ALAN_QUICK_REFERENCE.md](ALAN_QUICK_REFERENCE.md)** - Quick syntax reference for Alan platform
- **[BUILD_STATUS.md](BUILD_STATUS.md)** - Deployment history and status tracking
- **[CLAUDE.md](CLAUDE.md)** - MCP usage rules and workflow guidelines
- **[CONTEXT.md](CONTEXT.md)** - Workspace context and routing rules

## 🔧 Troubleshooting

### Common Issues

**Application Appears Empty After Deployment**
- Ensure you used `from_empty` migration for initial deployment
- Verify you're checking the Locations and Categories sections
- Check that sample data was actually included in the migration

**Build Shows Errors But Deployment Works**
- Trust actual deployment over IDE validation errors (known issue)
- Focus on whether the application functions correctly

**Authentication Problems**
- Double-check `sessions/config.alan` settings
- Verify password-initializer syntax in the Users/Passwords section
- Ensure you're using the exact username from the initializer

### Getting Help
- Refer to `PROJECT_OVERVIEW_AND_LESSONS_LEARNED.md` for detailed issue explanations
- Check `ALAN_QUICK_REFERENCE.md` for correct syntax patterns
- Review `_ref/` directory for additional Alan platform documentation

## 📈 Phases Implemented

✅ **Phase 1b** - Foundation Rebuild (Locations & Categories)
✅ **Phase 2** - Staff + Users + Authentication
✅ **Phase 3** - Found Items + Loss Reports
✅ **Phase 4** - Matches (linking Found Items ↔ Loss Reports)
✅ **Phase 5** - Dashboard + Staff Reference Sets + UI Polish

---

*Built with the Alan Platform*
*Last updated: 2026-04-09*