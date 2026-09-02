#!/usr/bin/env python3
"""
Fix all route files to support supervisor access
"""
import re
from pathlib import Path

# Pattern to match the president-only check
pattern = re.compile(
    r'# Get president ID(?: for filtering)?\s+'
    r'from app\.models\.president import President\s+'
    r'result_pres = await db\.execute\(\s+'
    r'select\(President\)\.where\(President\.user_id == current_user\.id\)\s+'
    r'\)\s+'
    r'president = result_pres\.scalar_one_or_none\(\)\s+'
    r'if not president:\s+'
    r'raise HTTPException\(status_code=403, detail="Not authorized as president"\)\s+'
    r'president_id = president\.id',
    re.MULTILINE
)

replacement = '# Get president ID for filtering (works for both presidents and supervisors)\n    president_id = await get_president_id_for_user(current_user, db)'

# Files to fix
files = [
    'app/api/v1/routes/lectures.py',
    'app/api/v1/routes/guardian.py',
    'app/api/v1/routes/supervisor.py',
]

for filepath in files:
    path = Path(filepath)
    if not path.exists():
        print(f"❌ {filepath} not found")
        continue
    
    content = path.read_text()
    matches = pattern.findall(content)
    
    if not matches:
        print(f"✓ {filepath} - no changes needed")
        continue
    
    # Replace all occurrences
    new_content = pattern.sub(replacement, content)
    
    # Add import if not present
    if 'from app.core.multi_tenancy import get_president_id_for_user' not in new_content:
        # Find the imports section and add it
        import_pattern = r'(from app\.core\.dependencies import [^\n]+)'
        new_content = re.sub(
            import_pattern,
            r'\1\nfrom app.core.multi_tenancy import get_president_id_for_user',
            new_content,
            count=1
        )
    
    path.write_text(new_content)
    print(f"✅ {filepath} - fixed {len(matches)} occurrence(s)")

print("\n✨ Done!")
