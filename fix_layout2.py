import re

file_path = '/Users/fuadaslam/fuad/service_manager_app/lib/features/dashboard/presentation/widgets/super_admin_view.dart'

with open(file_path, 'r') as f:
    content = f.read()

# Instead of complex regex, let's use string replacements or simple regex for each
def fix_tab(content, tab_marker_start, header_str):
    # Find the class and its return ResponsiveLayout
    pattern = re.compile(r'(\s+)return ResponsiveLayout\(\s*maxWidth:\s*1000,\s*padding:\s*EdgeInsets\.zero,\s*child:\s*Column\(\s*children:\s*\[\s*(_HeaderSection\(.*?\'?\)?\s*,)\s*Expanded\(', re.DOTALL)
    
    def replacer(m):
        indent = m.group(1)
        header = m.group(2)
        return f'{indent}return Column(\n{indent}  children: [\n{indent}    {header}\n{indent}    Expanded(\n{indent}      child: ResponsiveLayout(\n{indent}        maxWidth: 1000,\n{indent}        padding: EdgeInsets.zero,\n{indent}        child: '
    
    # We will just do a global replace for all of them using a more permissive regex for HeaderSection
    return content

# Let's fix the regex to allow parentheses inside HeaderSection.
# HeaderSection ends with a comma and newline.
pattern = re.compile(r'(\s+)return ResponsiveLayout\(\s*maxWidth:\s*1000,\s*padding:\s*EdgeInsets\.zero,\s*child:\s*Column\(\s*children:\s*\[\s*(_HeaderSection\(.*?\),)\s*Expanded\(', re.DOTALL)

def replacer(m):
    indent = m.group(1)
    header = m.group(2)
    return f'{indent}return Column(\n{indent}  children: [\n{indent}    {header}\n{indent}    Expanded(\n{indent}      child: ResponsiveLayout(\n{indent}        maxWidth: 1000,\n{indent}        padding: EdgeInsets.zero,\n{indent}        child: '

# Replace all start tags
new_content = pattern.sub(replacer, content)

# Now for the end tags. The end tags were:
#              ),
#            ),
#          ],
#        ),
#      );
# We want to change them to:
#              ),
#            ),
#          ),
#        ],
#      ),
#    );
# But the number of spaces can vary. Let's just find the `];` or similar end. Wait, no.
# The `\);\n\s*\]` etc. is too hard to parse accurately without an AST. Let's write a simple brace matcher.

def process_file(text):
    out = []
    lines = text.split('\n')
    i = 0
    while i < len(lines):
        # find `return ResponsiveLayout(`
        if 'return ResponsiveLayout(' in lines[i] and 'maxWidth: 1000' in lines[i+1]:
            # check if child is Column
            j = i
            while 'child: Column(' not in lines[j] and j < i+5:
                j += 1
            if j < i+5:
                # We found one!
                indent = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
                out.append(indent + 'return Column(')
                out.append(indent + '  children: [')
                j += 2 # skip child: Column( and children: [
                # Now append HeaderSection
                while '_HeaderSection' not in lines[j]:
                    j += 1
                while '),' not in lines[j]:
                    out.append(lines[j])
                    j += 1
                out.append(lines[j]) # the line with `),`
                j += 1
                # Now we expect Expanded(
                while 'Expanded(' not in lines[j]:
                    j += 1
                out.append(indent + '    Expanded(')
                out.append(indent + '      child: ResponsiveLayout(')
                out.append(indent + '        maxWidth: 1000,')
                out.append(indent + '        padding: EdgeInsets.zero,')
                
                # The child of ResponsiveLayout will be the child of Expanded
                child_line = lines[j+1].replace('child:', 'child:').strip()
                out.append(indent + '        ' + child_line)
                
                # Now we need to swap the closing braces
                # The structure was:
                #     return ResponsiveLayout( ... Column( children: [ _Header, Expanded( child: X ) ] ) );
                # We need to find the matching brace for `return ResponsiveLayout(` and rewrite the end.
                # Actually, an easier way is just to keep lines[j+2:] and replace the last `    );`
                # Let's just read until we see the end of the `return` statement.
                open_braces = 0
                open_parens = 1 # for return ResponsiveLayout(
                # We will just parse character by character to find the end of the statement!
                pass 
                
        out.append(lines[i])
        i += 1
    return '\n'.join(out)

# Actually, the simplest way is to manually do the replacements for the 6 occurrences using multi_replace_file_content!
