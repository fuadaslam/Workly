import re

filepath = 'lib/features/dashboard/presentation/widgets/super_admin_view.dart'
with open(filepath, 'r') as f:
    text = f.read()

tabs = [
    ("class _BranchManagementTab", "class _LeaveManagementTab"),
    ("class _LeaveManagementTab", "class _AdminManagementTab"),
    ("class _AdminManagementTab", "class _AgentManagementTab"),
    ("class _AgentManagementTab", "class _AccessControlTab"),
    ("class _AccessControlTab", "class _SystemSettingsTab"),
    ("class _SystemSettingsTabState", "class _SettingsTab"),
]

for start_marker, end_marker in tabs:
    start_idx = text.find(start_marker)
    end_idx = text.find(end_marker)
    
    chunk = text[start_idx:end_idx]
    
    # Replace top
    pattern = re.compile(
        r'(return\s+ResponsiveLayout\(\s*maxWidth:\s*1000,\s*padding:\s*EdgeInsets\.zero,\s*child:\s*Column\(\s*(?:crossAxisAlignment:\s*CrossAxisAlignment\.[a-zA-Z]+,\s*)?children:\s*\[\s*)'
        r'(_HeaderSection\(.*?\),?\s*)'
        r'(Expanded\(\s*(?:child:\s*)?)',
        re.DOTALL
    )
    
    def repl(m):
        header = m.group(2)
        return f"return Column(\n      children: [\n        {header.strip()},\n        Expanded(\n          child: ResponsiveLayout(\n            maxWidth: 1000,\n            padding: EdgeInsets.zero,\n            child: "

    new_chunk, count = pattern.subn(repl, chunk, count=1)
    
    if count == 1:
        # Replace bottom
        # We find the LAST occurrence of the exact bottom block
        last_brace = new_chunk.rfind('  }')
        if last_brace != -1:
            bottom_pattern = re.compile(r'\s*\)\s*,\n\s*\]\s*,\n\s*\)\s*,\n\s*\)\s*;\n\s*\}')
            matches = list(bottom_pattern.finditer(new_chunk))
            if matches:
                last_match = matches[-1]
                new_bottom = "\n            ),\n          ),\n        ),\n      ],\n    );\n  }"
                new_chunk = new_chunk[:last_match.start()] + new_bottom + new_chunk[last_match.end():]
                print(f"Successfully processed {start_marker}")
            else:
                print(f"Failed to match bottom for {start_marker}")
        else:
            print(f"Failed to find last brace for {start_marker}")
            
    text = text[:start_idx] + new_chunk + text[end_idx:]

with open(filepath, 'w') as f:
    f.write(text)

