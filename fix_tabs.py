import re

filepath = 'lib/features/dashboard/presentation/widgets/super_admin_view.dart'
with open(filepath, 'r') as f:
    text = f.read()

# For each tab, we want to find the build method, and within it, replace the return ResponsiveLayout
def process_tab(start_marker, end_marker=None):
    global text
    # Find the start index
    start_idx = text.find(start_marker)
    if start_idx == -1:
        print(f"Start marker not found: {start_marker}")
        return
    
    if end_marker:
        end_idx = text.find(end_marker, start_idx)
    else:
        end_idx = len(text)
        
    chunk = text[start_idx:end_idx]
    
    # Replace the top part
    # Pattern: 
    # return ResponsiveLayout(
    #   maxWidth: 1000,
    #   padding: EdgeInsets.zero,
    #   child: Column(
    #     children: [
    #       _HeaderSection(...),
    #       Expanded(
    
    pattern = re.compile(
        r'(return\s+ResponsiveLayout\(\s*maxWidth:\s*1000,\s*padding:\s*EdgeInsets\.zero,\s*child:\s*Column\(\s*(?:crossAxisAlignment:\s*CrossAxisAlignment\.start,\s*)?children:\s*\[\s*)'
        r'(_HeaderSection\([^)]*\),?\s*)'
        r'(Expanded\()',
        re.DOTALL
    )
    
    def repl(m):
        header = m.group(2)
        expanded = m.group(3)
        return f"return Column(\n      children: [\n        {header.strip()},\n        Expanded(\n          child: ResponsiveLayout(\n            maxWidth: 1000,\n            padding: EdgeInsets.zero,"
        
    chunk, n = pattern.subn(repl, chunk, count=1)
    if n > 0:
        print(f"Top replaced for {start_marker}")
    else:
        print(f"Top NOT replaced for {start_marker}")
        
    if n > 0:
        # Replace the bottom part
        # We find the matching closing bracket of the entire `return Column(` by doing a bracket match,
        # OR we just know it's at the end of the chunk before `  }\n`
        # Let's do a robust bracket match from `return Column(`!
        ret_idx = chunk.find('return Column(')
        
        # simple bracket counter
        count = 0
        in_string = False
        str_char = ''
        end_ret_idx = -1
        
        for i in range(ret_idx, len(chunk)):
            c = chunk[i]
            if in_string:
                if c == str_char and chunk[i-1] != '\\':
                    in_string = False
            else:
                if c in ("'", '"'):
                    in_string = True
                    str_char = c
                elif c == '(': count += 1
                elif c == ')': 
                    count -= 1
                    if count == 0:
                        end_ret_idx = i
                        break
                        
        if end_ret_idx != -1:
            # The closing is `)` at end_ret_idx. Wait, it's followed by `;`
            # The original ended with `);` which closed ResponsiveLayout.
            # Wait, the original `return ResponsiveLayout(` was replaced by `return Column(`.
            # But we added `Expanded( child: ResponsiveLayout(` which means we added TWO opening parentheses: `Expanded(` and `ResponsiveLayout(`.
            # Actually, the original was:
            # return ResponsiveLayout( -> now return Column(
            #   child: Column(         -> now (removed)
            #     children: [          -> now children: [
            #       Expanded(          -> Expanded(
            #         child: Widget(   -> child: ResponsiveLayout( child: Widget(
            # So the original had 3 open parens (ResponsiveLayout, Column, Expanded), now we have 4 open parens (Column, Expanded, ResponsiveLayout, Widget).
            # Wait, no. The new code is:
            # return Column(
            #   children: [
            #     _HeaderSection(),
            #     Expanded(
            #       child: ResponsiveLayout(
            #         child: Widget(
            # The original code was:
            # return ResponsiveLayout(
            #   child: Column(
            #     children: [
            #       _HeaderSection(),
            #       Expanded(
            #         child: Widget(
            # This means originally we had `ResponsiveLayout`, `Column`, `Expanded` (3) around `Widget`.
            # Now we have `Column`, `Expanded`, `ResponsiveLayout` (3) around `Widget`.
            # Wait! The number of open brackets/parentheses is EXACTLY THE SAME!
            # The ONLY difference is that `_HeaderSection` is now a direct child of the outermost `Column`, whereas before it was inside the inner `Column`!
            pass

