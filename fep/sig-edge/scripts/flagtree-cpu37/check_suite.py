import sys
import xml.etree.ElementTree as ET

cases = ET.parse(sys.argv[1]).getroot().findall('.//testcase')
assert len(cases) == int(sys.argv[2]), len(cases)
assert all(not any(c.find(t) is not None for t in ['failure', 'error', 'skipped'])
           for c in cases), 'failed, errored or skipped tests'
print('suite PASS', len(cases), 'passed, 0 skipped')
