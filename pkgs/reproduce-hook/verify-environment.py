import json
import os
import re
import socket
import sys

import colorama
from colorama import Fore, Style

CLOUDLAB_SIGNUP = "https://cloudlab.us/signup.php"
CLOUDLAB_HWINFO = "https://docs.cloudlab.us/hardware.html"

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def bold(text):
    return Style.BRIGHT + text + Style.RESET_ALL

def highlight(text):
    return Style.BRIGHT + Fore.GREEN + text + Style.RESET_ALL

def highlightcmd(text):
    return Style.BRIGHT + Fore.YELLOW + text + Style.RESET_ALL

def info(description):
    eprint('[{}INFO{}] {}'.format(Fore.BLUE, Style.RESET_ALL, description))

def check(description, condition):
    if condition:
        eprint('[ {}OK{} ] {}'.format(Fore.GREEN, Style.RESET_ALL, description))
    else:
        eprint('[{}FAIL{}] {}'.format(Fore.RED, Style.RESET_ALL, description))

    return condition

def verify_cloudlab_infra(reqs):
    instanceReq = reqs.get('cloudlab', False)
    if instanceReq:
        fqdn = socket.getfqdn()
        matches = re.match(r"^(?P<machineType>[a-z0-9]+)-?(?P<machineId>[0-9]+)\.(?P<cluster>[a-z]+)\.cloudlab\.us$", fqdn)

        if not check('Using a CloudLab machine', matches):
            eprint('You must be using a machine on CloudLab.')
            eprint('If you are affiliated with an institution, you can request an account at:')
            eprint('          ' + highlight(CLOUDLAB_SIGNUP))

            eprint()
            eprint('For more information on the specifications of the machines, see {}.'.format(highlight(CLOUDLAB_HWINFO)))

            if isinstance(instanceReq, str):
                eprint('This experiment requires a "{}" node.'.format(instanceReq))

            return False

        machineType = matches.group('machineType')
        if isinstance(instanceReq, str) and \
           not check('Using instance type "{}"'.format(instanceReq), machineType == instanceReq):
            eprint('You must be using the "{}" instance type. You are currently using "{}".'.format(instanceReq, machineType))

            return False

    return True

if __name__ == '__main__':
    colorama.init()

    if not os.getenv('REQUIREMENTS'):
        eprint('Pass requirements with REQUIREMENTS')
        sys.exit(1)

    requirements = json.loads(os.getenv('REQUIREMENTS'))

    if requirements['notes']:
        print(requirements['notes'])

    tests = [
        verify_cloudlab_infra(requirements),
    ]

    if sum(map(lambda x: not x, tests)) > 0:
        eprint()

        if os.getenv('IGNORE_REQUIREMENTS'):
            eprint('Warning: Continuing despite of unmet system requirements. The results may not be reproducible.')
        else:
            eprint('System requirement check failed. Please verify that your setup matches the requirements above.')
            eprint('If you would like to skip the checks, set {}.'.format(highlightcmd('IGNORE_REQUIREMENTS=1')))
            sys.exit(1)
