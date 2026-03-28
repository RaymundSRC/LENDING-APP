import os
import re

count = 0
for r, d, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            p = os.path.join(r, f)
            with open(p, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # Replace explicitly escaped dollar signs (\$)
            new_content = content.replace('\\$', '₱')
            # Replace USD text representation
            new_content = new_content.replace('($)', '(₱)')
            # Replace Dollar signs that are physically typed with spaces (e.g. "$ 500")
            new_content = new_content.replace(' $', ' ₱')
            new_content = new_content.replace('$ ', '₱ ')
            new_content = new_content.replace('USD', 'PHP')
            
            if new_content != content:
                with open(p, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                print('Replaced:', p)
                count += 1

print(f"Total files updated: {count}")
