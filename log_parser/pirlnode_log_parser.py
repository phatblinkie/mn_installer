#!/usr/bin/env python3

from systemd import journal

j = journal.Reader()
j.this_boot()
j.log_level(journal.LOG_INFO)
j.add_match(_SYSTEMD_UNIT="pirlnode.service")

for entry in j:
    print(entry['MESSAGE'])