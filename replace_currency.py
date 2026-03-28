import os

# Files that failed the chunk replacement
files_to_fix = [
    'lib/screens/members_widgets/member_profile_modal.dart',
    'lib/screens/loans_widgets/loan_profile_modal.dart',
    'lib/screens/dashboard_widgets/summary_cards.dart',
    'lib/screens/dashboard_widgets/recent_records.dart',
    'lib/screens/loans_widgets/loans_list.dart',
    'lib/screens/members_widgets/add_member_modal.dart' # TargetAmount target had \$ in strings 
]

cwd = 'c:/Users/raymu/OneDrive/Desktop/LENDING APP/'

for f in files_to_fix:
    path = os.path.join(cwd, f)
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as file:
            content = file.read()
        
        # We replace the literal python string \$ with ₱. 
        # In dart code, it's typically '\$100' or '\$${variable}'
        # This converts to '₱100' or '₱${variable}'
        new_content = content.replace('\\$', '₱')
        
        if new_content != content:
            with open(path, 'w', encoding='utf-8') as file:
                file.write(new_content)
            print(f"Replaced currency in {f}")
