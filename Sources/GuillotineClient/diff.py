import os

src_root = os.getenv('SRCROOT')

file_res = []
os.chdir(src_root)
with os.popen(f'git diff --name-only HEAD', 'r') as fp:
    files = fp.readlines()
    for file in files:
        file = os.path.join(src_root, file.strip())
        if file not in file_res:
            file_res.append(file)

print(",".join(file_res))
