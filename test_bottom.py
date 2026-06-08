import re

filepath = 'lib/features/dashboard/presentation/widgets/super_admin_view.dart'
with open(filepath, 'r') as f:
    text = f.read()

pattern = re.compile(
    r'(return\s+ResponsiveLayout\(\s*maxWidth:\s*1000,\s*padding:\s*EdgeInsets\.zero,\s*child:\s*Column\(\s*(?:crossAxisAlignment:\s*CrossAxisAlignment\.[a-zA-Z]+,\s*)?children:\s*\[\s*)'
    r'(_HeaderSection\(.*?\),?\s*)'
    r'(Expanded\(\s*(?:child:\s*)?)',
    re.DOTALL
)

matches = list(pattern.finditer(text))

for m in matches:
    start_idx = m.start()
    paren_idx = text.find('(', start_idx)
    
    count = 0
    in_string = False
    str_char = ''
    end_idx = -1
    
    for i in range(paren_idx, len(text)):
        c = text[i]
        if in_string:
            if c == str_char and text[i-1] != '\\':
                in_string = False
        else:
            if c in ("'", '"'):
                in_string = True
                str_char = c
            elif c == '(': count += 1
            elif c == ')': 
                count -= 1
                if count == 0:
                    end_idx = i
                    break
                    
    print("Found end at:", end_idx)
    print("Last 40 chars:", repr(text[end_idx-40:end_idx+2]))

