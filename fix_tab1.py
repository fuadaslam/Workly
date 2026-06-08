import re

filepath = 'lib/features/dashboard/presentation/widgets/super_admin_view.dart'
with open(filepath, 'r') as f:
    text = f.read()

start_marker = "class _BranchManagementTab extends ConsumerWidget {"
end_marker = "class _LeaveManagementTab extends ConsumerWidget {"

start_idx = text.find(start_marker)
end_idx = text.find(end_marker)

chunk = text[start_idx:end_idx]

# Top replace
pattern = re.compile(
    r'(return\s+ResponsiveLayout\(\s*maxWidth:\s*1000,\s*padding:\s*EdgeInsets\.zero,\s*child:\s*Column\(\s*(?:crossAxisAlignment:\s*CrossAxisAlignment\.[a-zA-Z]+,\s*)?children:\s*\[\s*)'
    r'(_HeaderSection\(.*?\),?\s*)'
    r'(Expanded\(\s*(?:child:\s*)?)',
    re.DOTALL
)

def repl(m):
    header = m.group(2)
    return f"return Column(\n      children: [\n        {header.strip()},\n        Expanded(\n          child: ResponsiveLayout(\n            maxWidth: 1000,\n            padding: EdgeInsets.zero,\n            child: "

new_chunk = pattern.sub(repl, chunk)

# Bottom replace
# We need to replace:
#           ),
#         ],
#       ),
#     );
#   }
# With:
#             ),
#           ),
#         ),
#       ],
#     );
#   }
# Find the LAST `  }` in new_chunk
last_brace = new_chunk.rfind('  }')
if last_brace != -1:
    # go back to find `], ), );`
    bottom_pattern = re.compile(r'\n\s*\),\n\s*\]\s*,\n\s*\)\s*,\n\s*\)\s*;\n\s*\}')
    
    # search for the last match
    matches = list(bottom_pattern.finditer(new_chunk))
    if matches:
        last_match = matches[-1]
        new_bottom = "\n            ),\n          ),\n        ),\n      ],\n    );\n  }"
        new_chunk = new_chunk[:last_match.start()] + new_bottom + new_chunk[last_match.end():]

text = text[:start_idx] + new_chunk + text[end_idx:]

with open(filepath, 'w') as f:
    f.write(text)

