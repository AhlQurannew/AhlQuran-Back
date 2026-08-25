"""
Script to replace all president-only checks with president_or_supervisor checks in route files
"""
import re
from pathlib import Path

# Pattern to find and replace
old_pattern = r'''# Get president ID for filtering
    from app\.models\.president import President
    result_pres = await db\.execute\(
        select\(President\)\.where\(President\.user_id == current_user\.id\)
    \)
    president = result_pres\.scalar_one_or_none\(\)
    
    if not president:
        raise HTTPException\(status_code=403, detail="Not authorized as president"\)
    
    president_id = president\.id'''

new_text = '''# Get president ID for filtering (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)'''

# Files to process
files_to_fix = [
    'app/api/v1/routes/teacher.py',
    'app/api/v1/routes/student.py',
    'app/api/v1/routes/lecture.py',
    'app/api/v1/routes/attendance.py',
]

for file_path in files_to_fix:
    full_path = Path(file_path)
    if not full_path.exists():
        print(f"Skipping {file_path} - file not found")
        continue
    
    print(f"Processing {file_path}...")
    content = full_path.read_text(encoding='utf-8')
    
    # Count occurrences
    count = len(re.findall(old_pattern, content, re.MULTILINE))
    
    if count > 0:
        # Replace all occurrences
        new_content = re.sub(old_pattern, new_text, content, flags=re.MULTILINE)
        full_path.write_text(new_content, encoding='utf-8')
        print(f"  ✓ Replaced {count} occurrence(s)")
    else:
        print(f"  - No occurrences found")

print("\nDone!")
