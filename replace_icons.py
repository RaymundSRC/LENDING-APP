import os

count = 0
for r, d, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            p = os.path.join(r, f)
            with open(p, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # replace dollar icons with generic wallet/payments icons
            new_content = content.replace('Icons.attach_money', 'Icons.account_balance_wallet')
            new_content = new_content.replace('Icons.monetization_on', 'Icons.payments')
            
            if new_content != content:
                with open(p, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                print('Replaced:', p)
                count += 1

print(f"Total files updated: {count}")
