import re

filepath = 'lib/features/dashboard/presentation/widgets/super_admin_view.dart'
with open(filepath, 'r') as f:
    text = f.read()

def process():
    global text
    
    # We find all occurrences of return ResponsiveLayout( that wrap a Column that wraps a _HeaderSection
    pattern = re.compile(
        r'(return\s+ResponsiveLayout\(\s*maxWidth:\s*1000,\s*padding:\s*EdgeInsets\.zero,\s*child:\s*Column\(\s*(?:crossAxisAlignment:\s*CrossAxisAlignment\.[a-zA-Z]+,\s*)?children:\s*\[\s*)'
        r'(_HeaderSection\(.*?\),?\s*)'
        r'(Expanded\(\s*(?:child:\s*)?)',
        re.DOTALL
    )
    
    matches = list(pattern.finditer(text))
    print(f"Found {len(matches)} tabs to process")
    
    # Process from right to left so indices don't change
    for m in reversed(matches):
        start_idx = m.start()
        
        # We need to find the matching closing bracket for the ResponsiveLayout `return ResponsiveLayout(`
        paren_idx = text.find('(', start_idx)
        
        count = 0
        in_string = False
        str_char = ''
        end_idx = -1
        
        # We also want to find the end of Column children `],` which is right before the end of Column
        # Let's just track the Column children array closing `]`?
        
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
                        
        if end_idx != -1:
            header = m.group(2)
            
            # Now we find the Expanded closing parenthesis.
            # Wait, the inner content of Expanded is everything between `m.end()` and the closing `]` of children array!
            # The structure is:
            # children: [
            #   _HeaderSection(...),
            #   Expanded(
            #     child: INNER_CONTENT
            #   ),
            # ],
            
            # Since we just want to change it to:
            # return Column(
            #   children: [
            #     _HeaderSection(...),
            #     Expanded(
            #       child: ResponsiveLayout(
            #         maxWidth: 1000, padding: EdgeInsets.zero, child: INNER_CONTENT
            #       )
            #     )
            #   ]
            # )
            
            # We can literally just replace the beginning:
            new_top = f"return Column(\n      children: [\n        {header.strip()}\n        Expanded(\n          child: ResponsiveLayout(\n            maxWidth: 1000,\n            padding: EdgeInsets.zero,\n            child: "
            text = text[:m.start()] + new_top + text[m.end(3):]
            
            # Since we replaced `return ResponsiveLayout( ... child: Column( children: [ _HeaderSection, Expanded( child: `
            # With `return Column( children: [ _HeaderSection, Expanded( child: ResponsiveLayout( child: `
            # The brackets are EXACTLY THE SAME NUMBER. 
            # Original: 
            #   ResponsiveLayout ( 
            #     Column ( 
            #       Expanded ( 
            #         INNER 
            #       )
            #     )
            #   )
            # New:
            #   Column ( 
            #     Expanded ( 
            #       ResponsiveLayout ( 
            #         INNER 
            #       )
            #     )
            #   )
            #
            # The ONLY issue is that `ResponsiveLayout` might have been ended with `);` and `Expanded` with `),` and `Column` with `),`.
            # Wait, the original end of `return ResponsiveLayout(` is exactly `);`.
            # The new end of `return Column(` is exactly `);`.
            # The original inner closures were `),` (Expanded) and `],` (children) and `),` (Column).
            # So the original was:
            #         ), // inner
            #       ), // Expanded
            #     ], // children
            #   ), // Column
            # ); // ResponsiveLayout
            # 
            # We want:
            #           ), // inner
            #         ), // ResponsiveLayout
            #       ), // Expanded
            #     ], // children
            #   ); // Column
            #
            # So we need to replace `],\n      ),\n    );` with `  ),\n        ),\n      ],\n    );`
            # Let's just find the end of the `return` statement (which is `end_idx` before we modified text, but we shifted it).
            # Actually, `count=0` finds the `)` of `return ResponsiveLayout(`.
            pass
            
    with open(filepath, 'w') as f:
        f.write(text)

process()
