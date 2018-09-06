#!/usr/bin/env python3

from systemd import journal

def main():
    j = journal.Reader()
    j.this_boot()
    j.log_level(journal.LOG_INFO)
    j.add_match(_SYSTEMD_UNIT="pirlnode.service")

    # Look for these key words or phrases
    onetime_keyitems = ['UDP listener up', 'RLPx listener up', 'IPC endpoint opened']
    importing_blocks = 'Imported new chain segment'
    importing_blocks_check = 0
    sending_proof = ' masternode sending proof of activity for block'
    sending_proof_check = 0
    for entry in j:
        if onetime_keyitems in entry['MESSAGE']:
            print("This is good --> {}".format(entry['MESSAGE']))

        if importing_blocks in entry['MESSAGE'] and importing_blocks_check == 0:
            importing_blocks_check = 1
            print("Importing blocks is good --> {}".format(entry['MESSAGE']))

        if sending_proof in entry['MESSAGE'] and sending_proof_check == 0:
            sending_proof_check = 1
            print("Sending proof is good --> {}".format(entry['MESSAGE']))

if __name__ == "__main__":
    main()