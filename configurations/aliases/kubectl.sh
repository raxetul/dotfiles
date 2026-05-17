# kubectl.sh — replaces the oh-my-zsh `kubectl` plugin.
alias k='kubectl'

alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kga='kubectl get all'
alias kgn='kubectl get nodes'
alias kgd='kubectl get deployments'
alias kgns='kubectl get namespaces'

alias kdp='kubectl describe pod'
alias kdn='kubectl describe node'
alias kds='kubectl describe service'

alias kdel='kubectl delete'
alias kdelp='kubectl delete pod'

alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'

alias klogs='kubectl logs -f'
alias kexec='kubectl exec -it'

alias kctx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'
