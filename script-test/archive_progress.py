#!/usr/bin/env python3
import re
import sys
from pathlib import Path

# Force UTF-8 output encoding for Windows console
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8')

def archive_sessions(max_kept=25):
    script_dir = Path(__file__).resolve().parent
    root = script_dir.parent
    main_file = root / "claude-progress.md"
    archive_file = root / "docs" / "claude-progress-archive.md"
    
    if not main_file.exists():
        print("Error: Main progress file (claude-progress.md) not found.")
        return False
        
    with open(main_file, "r", encoding="utf-8") as f:
        main_content = f.read()
        
    # Split by session headers
    sessions = re.split(r'(?=\n### Phiên \d+)', main_content)
    
    header = sessions[0]
    session_blocks = sessions[1:]
    
    if len(session_blocks) <= max_kept:
        # No archiving needed
        print(f"Progress file has {len(session_blocks)} sessions (<= {max_kept}). No archiving needed.")
        return True
        
    # We keep the first max_kept sessions (newest ones)
    keep_blocks = session_blocks[:max_kept]
    archive_blocks = session_blocks[max_kept:]
    
    # Extract numbers to identify range of archived sessions
    archived_nums = []
    for block in archive_blocks:
        match = re.search(r'### Phiên (\d+)', block)
        if match:
            archived_nums.append(int(match.group(1)))
            
    if not archived_nums:
        print("Warning: Could not parse session numbers from archive blocks.")
        return False
        
    min_archived = min(archived_nums)
    max_archived = max(archived_nums)
    
    # In main progress, sessions are in descending order.
    # In archive, we want them in ascending order (older first).
    archive_blocks.reverse()
    archive_str = "".join(archive_blocks)
    
    # 1. Update docs/claude-progress-archive.md
    if archive_file.exists():
        with open(archive_file, "r", encoding="utf-8") as f:
            archive_content = f.read()
            
        # Locate the bottom guide line and strip it
        guide_line = '_Thêm phiên mới theo format trên. Giữ mục "Trạng thái Hiện tại" luôn cập nhật._'
        archive_content = archive_content.replace(guide_line, "").strip()
        
        # Append the new archived sessions and the guide line
        new_archive_content = archive_content + "\n" + archive_str.strip() + "\n\n" + guide_line + "\n"
        
        with open(archive_file, "w", encoding="utf-8") as f:
            f.write(new_archive_content)
        print(f"Archived {len(archive_blocks)} sessions (Phiên {min_archived:03d} - {max_archived:03d}) to {archive_file.name}")
    else:
        print(f"Error: Archive file not found at {archive_file}")
        return False
        
    # 2. Update claude-progress.md header link to reflect new archive range
    # Find pattern like "(Phiên 001 - 050)" and update to "(Phiên 001 - <max_archived>)"
    new_range_str = f"Phiên 001 - {max_archived:03d}"
    updated_header = re.sub(r'Phiên \d+ - \d+', new_range_str, header)
    
    # 3. Write back the updated claude-progress.md
    new_main_content = updated_header + "".join(keep_blocks)
    # Ensure the helper text exists at the end of the file
    helper_text = '\n\n_Thêm phiên mới theo format trên. Giữ mục "Trạng thái Hiện tại" luôn cập nhật._\n'
    if not new_main_content.endswith(helper_text):
        new_main_content = new_main_content.rstrip() + helper_text
        
    with open(main_file, "w", encoding="utf-8") as f:
        f.write(new_main_content)
        
    print(f"Successfully cleaned up claude-progress.md. Kept {len(keep_blocks)} newest sessions.")
    return True

if __name__ == "__main__":
    archive_sessions(max_kept=25)
