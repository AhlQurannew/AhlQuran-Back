# Sustainable Deployment & Migration Workflow

## Overview

This project uses a **fully automated migration system**. Migrations run automatically on every container startup, ensuring database schema is always up-to-date.

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                  docker-compose up                      │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Database Container Starts                   │
│  • PostgreSQL 15                                        │
│  • Health check: pg_isready                             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│            Backend Container Starts                      │
│  • Waits for database health check                      │
│  • Runs startup.sh script                               │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              scripts/startup.sh                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 1. Wait for database (pg_isready)                │  │
│  │ 2. Run: alembic upgrade head                     │  │
│  │    • Applies all pending migrations              │  │
│  │    • Exits if migration fails (fail-safe)        │  │
│  │ 3. Start: uvicorn app.main:app                   │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│           FastAPI Application Running                    │
│  • API available at http://localhost:8000               │
│  • WebSocket at ws://localhost:8000/ws/messages         │
│  • Auto-reload enabled in development                   │
└─────────────────────────────────────────────────────────┘
```

## Developer Workflow

### Adding a New Feature That Needs Database Changes

```
┌─────────────────────────────────────┐
│ 1. Update SQLAlchemy Models         │
│    (app/models/*.py)                │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 2. Create Migration                 │
│    $ docker-compose exec backend \  │
│      alembic revision -m "add_col"  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 3. Edit Migration File              │
│    (alembic/versions/004_*.py)      │
│    • Implement upgrade()            │
│    • Implement downgrade()          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 4. Test Locally                     │
│    $ docker-compose restart backend │
│    (Migration runs automatically)   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 5. Commit to Git                    │
│    $ git add alembic/versions/      │
│    $ git commit -m "Add feature"    │
│    $ git push                       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 6. Deploy to Production             │
│    $ docker-compose up -d --build   │
│    (Migration runs automatically)   │
└─────────────────────────────────────┘
```

## Production Deployment

### Zero-Downtime Deployment Strategy

For production environments, consider this approach:

1. **Backward Compatible Migrations**
   - New columns should be nullable initially
   - Don't drop columns until next release
   - Use separate migrations for data and schema

2. **Deployment Steps**
   ```bash
   # 1. Pull latest code
   git pull origin main
   
   # 2. Rebuild and restart (migrations run automatically)
   docker-compose up -d --build
   
   # 3. Verify
   docker-compose logs -f backend
   ```

3. **Rollback Strategy**
   ```bash
   # If deployment fails, rollback to previous version
   git checkout <previous-commit>
   docker-compose up -d --build
   
   # Or manually rollback migration
   docker-compose exec backend alembic downgrade -1
   ```

## Migration Safety Checks

### Before Creating Migration

- [ ] Review model changes
- [ ] Consider existing data impact
- [ ] Plan backward compatibility
- [ ] Test with production-like data

### Before Deploying Migration

- [ ] Test upgrade on local database
- [ ] Test downgrade (rollback scenario)
- [ ] Check for data loss risks
- [ ] Backup production database
- [ ] Review migration file with team

### After Deployment

- [ ] Verify application logs
- [ ] Check database state
- [ ] Test key functionality
- [ ] Monitor for errors

## Current Migrations

| Revision | Description | Impact |
|----------|-------------|--------|
| 001 | Create attendance tables | New tables |
| 002 | Add unique constraint to attendances | Data integrity |
| 003 | Fix missing supervisor records | Data consistency fix |

## Key Benefits

✅ **Automatic** - No manual migration commands needed  
✅ **Safe** - Backend won't start if migrations fail  
✅ **Version Controlled** - All migrations in Git  
✅ **Repeatable** - Same process dev → staging → production  
✅ **Auditable** - Full migration history  
✅ **Consistent** - Database always matches code version  

## Troubleshooting

### Migration Fails on Startup

```bash
# View error
docker-compose logs backend

# Fix the migration file
nano alembic/versions/00X_*.py

# Restart to retry
docker-compose restart backend
```

### Need to Rollback

```bash
# Rollback one migration
docker-compose exec backend alembic downgrade -1

# Check current version
docker-compose exec backend alembic current
```

### Database Out of Sync

```bash
# Check alembic version table
docker-compose exec db psql -U ahlquran_user -d ahlquran_db \
  -c "SELECT * FROM alembic_version;"

# Force to specific version (use with caution!)
docker-compose exec db psql -U ahlquran_user -d ahlquran_db \
  -c "UPDATE alembic_version SET version_num = '003';"
```

## Best Practices Summary

1. **Always test migrations locally first**
2. **Keep migrations small and focused**
3. **Write reversible migrations when possible**
4. **Document complex migrations with comments**
5. **Backup production database before deploying**
6. **Monitor logs after deployment**
7. **Have a rollback plan ready**

---

**This is a sustainable system** - migrations are part of the deployment process, not a separate manual step.
