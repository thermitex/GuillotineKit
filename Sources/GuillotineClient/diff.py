import os, sys, json

src_root = sys.argv[1]

# Fetch mbox config
res = []
isMbox = False
config_path = os.path.join(src_root, '.mbox/config.json')
if os.path.exists(config_path):
    isMbox = True
    with open(config_path, 'r') as fp:
        config = json.load(fp)
        current_feature = config['current_feature_name']
        feature = config['features'][current_feature]
        repos = feature['repos']
        for repo in repos:
            if current_feature == '':
                res.append((repo['name'], repo['last_branch'], repo['last_branch']))
            else:
                res.append((repo['name'], feature['branch_prefix'] + feature['name'], repo['target_branch']))

file_res = []
for name, curr_branch, target_branch in res:
    final_path = os.path.join(src_root, name)
    os.chdir(final_path)
    with os.popen(f'git diff --name-only {target_branch}...{curr_branch}', 'r') as fp:
        files = fp.readlines()
        for file in files:
            file = os.path.join(final_path, file.strip())
            if file not in file_res:
                file_res.append(file)
    with os.popen(f'git diff --name-only HEAD', 'r') as fp:
        files = fp.readlines()
        for file in files:
            file = os.path.join(final_path, file.strip())
            if file not in file_res:
                file_res.append(file)
                
if not isMbox:
    os.chdir(src_root)
    with os.popen(f'git diff --name-only HEAD', 'r') as fp:
        files = fp.readlines()
        for file in files:
            file = os.path.join(src_root, file.strip())
            if file not in file_res:
                file_res.append(file)

print(",".join(file_res))
