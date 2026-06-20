import re

filepath = 'lib/features/dashboard/presentation/widgets/super_admin_view.dart'
with open(filepath, 'r') as f:
    text = f.read()

# Let's find all `  }\n` preceded by `    );\n` preceded by `      ),\n` preceded by `        ],\n`
pattern = re.compile(r'\s*\),\n\s*\]\s*,\n\s*\)\s*,\n\s*\)\s*;\n\s*\}')
matches = list(pattern.finditer(text))
print("Found matches:", len(matches))
for m in matches:
    print(repr(text[m.start():m.end()]))
