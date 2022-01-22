#!/bin/sh
# run ansible
# if [ "$HOSTNAME" = "archtop" ]; 
# then
#     echo "running playbook with laptop tags"
#     ansible-playbook /home/jared/Projects/lab-automation/ansible-playbooks/arch/playbook.yaml --ask-vault-pass --ask-become-pass --tags "laptop"
# else
#     echo "running playbook"
#     ansible-playbook $(pwd)/arch/playbook.yaml --ask-vault-pass --ask-become-pass
# fi


ansible-playbook $(pwd)/playbook.yaml --ask-vault-pass --ask-become-pass
