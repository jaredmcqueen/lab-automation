IP=$(kubectl -n argocd get svc argocd-server --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
NEW_PASSWORD="argocdpass"
argocd login $IP --insecure --username=admin --password=$PASSWORD
argocd account update-password --current-password=$PASSWORD --new-password=$NEW_PASSWORD
