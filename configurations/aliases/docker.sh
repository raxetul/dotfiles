# docker.sh — short forms for the daily docker / compose commands.
alias d='docker'

alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dexec='docker exec -it'
alias dlogs='docker logs -f'
alias dprune='docker system prune -af'

# Compose v2 ships as a docker subcommand; the legacy `docker-compose`
# binary is still installed for scripts that hard-code it.
alias dc='docker compose'
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dcp='docker compose ps'

alias dcb='docker compose build'
alias dcrr='docker compose run --rm'
alias dce='docker compose exec'

