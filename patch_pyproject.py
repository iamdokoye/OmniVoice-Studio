import re

with open('pyproject.toml') as f:
    c = f.read()

c = re.sub(r'torch = \[.*?\]', '', c, flags=re.DOTALL)
c = re.sub(r'torchaudio = \[.*?\]', '', c, flags=re.DOTALL)
lines = [l for l in c.splitlines(keepends=True)
         if '"torch==' not in l and '"torchaudio==' not in l]
c = ''.join(lines)

with open('pyproject.toml', 'w') as f:
    f.write(c)
