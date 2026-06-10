import sys
print(sys.executable)
print(sys.version)
import os
print(os.getcwd())
import subprocess
try:
    print(subprocess.check_output(['python', '--version'], stderr=subprocess.STDOUT))
except Exception as e:
    print(f"Error: {e}")
