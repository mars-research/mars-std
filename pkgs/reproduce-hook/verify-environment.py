import socket
import os
import sys
import json
import re

def check(description, condition):
    if condition:
        print('[ OK ] {}'.format(description))
    else:
        print('[FAIL] {}'.format(description))

    return condition

def verify_cloudlab_infra(reqs):
    requireCloudlab = reqs.get('cloudlab', False)
    if requireCloudlab:
        fqdn = socket.getfqdn()
        matches = re.match(r"^(?P<machineType>[a-z0-9]+)-?(?P<machineId>[0-9]+)\.(?P<cluster>[a-z]+)\.cloudlab\.us$", fqdn)

        if not check('Using a Cloudlab machine', matches):
            print('You must be using a Cloudlab machine.')
            print('If you are affiliated with an institution, you can request a Cloudlab account at:')
            print('          https://cloudlab.us/signup.php')

            return False

        machineType = matches.group('machineType')
        if isinstance(requireCloudlab, str) and \
           not check('Using instance type "{}"'.format(requireCloudlab), machineType == requireCloudlab):
            print('You must be using the "{}" instance type. You are currently using "{}".'.format(requireCloudlab, machineType))

            return False

    return True

if __name__ == '__main__':
    if not os.getenv('REQUIREMENTS'):
        print('Pass requirements with REQUIREMENTS')
        sys.exit(1)

    requirements = json.loads(os.getenv('REQUIREMENTS'))

    tests = [
        verify_cloudlab_infra(requirements),
    ]

    if sum(map(lambda x: not x, tests)) > 0:
        if os.getenv('IGNORE_REQUIREMENTS'):
            print('Continuing despite of unmet system requirements. The results may not be reproducible.')
        else:
            print('System requirement check failed. Please verify that your setup matches the requirements above.')
            print('If you would like to skip the checks, set the IGNORE_REQUIREMENTS environment variable.')
            sys.exit(1)
