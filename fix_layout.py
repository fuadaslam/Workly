import re

file_path = '/Users/fuadaslam/fuad/service_manager_app/lib/features/dashboard/presentation/widgets/super_admin_view.dart'

with open(file_path, 'r') as f:
    content = f.read()

# 1. Remove ConstrainedBox from SuperAdminView
content = content.replace(
'''                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: _buildCurrentTab(currentIndex, isSuperAdmin),
                    ),
                  ),
                ),''',
'''                Expanded(
                  child: _buildCurrentTab(currentIndex, isSuperAdmin),
                ),'''
)

# 2. Fix the tabs with ResponsiveLayout > Column > HeaderSection + Expanded

# Find all occurrences of the pattern
pattern = re.compile(
r'(\s+)return ResponsiveLayout\(\s*maxWidth:\s*1000,\s*padding:\s*EdgeInsets\.zero,\s*child:\s*Column\(\s*children:\s*\[\s*(_HeaderSection\([^)]+\),)\s*Expanded\(\s*child:\s*(.*?),\n\s*\),\n\s*\],\n\s*\),\n\s*\);',
re.DOTALL
)

def replacer(match):
    indent = match.group(1)
    header_section = match.group(2)
    expanded_child = match.group(3)
    
    # We will reconstruct the layout
    return f"""{indent}return Column(
{indent}  children: [
{indent}    {header_section}
{indent}    Expanded(
{indent}      child: ResponsiveLayout(
{indent}        maxWidth: 1000,
{indent}        padding: EdgeInsets.zero,
{indent}        child: {expanded_child},
{indent}      ),
{indent}    ),
{indent}  ],
{indent});"""

new_content = pattern.sub(replacer, content)

with open(file_path, 'w') as f:
    f.write(new_content)

print("Done")
