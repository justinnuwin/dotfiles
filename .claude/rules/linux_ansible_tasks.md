---
paths:
  - "ansible/**"
---

# Guidelines for Linux-specific Ansible tasks

Use explicit checks for OS distribution or system, NOT conditions unrelated to the target.
For example:

```ansible
- name: Correct task running only on Linux
  when: ansible_facts['system'] == 'Linux'

- name: Correct task running only on Debian-based systems
  when: ansible_facts['os_family'] == 'Debian'

- name: **INCORRECT** task running only on any Linux-based systems
  when: ansible_facts['os_family'] != 'Darwin'
```
