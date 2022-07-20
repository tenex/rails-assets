#!/bin/zsh
mkdir -p $HOME/backup-logs
log_dest="$HOME/backup-logs/$(date '+%s').log"
(
    /usr/bin/gsutil -m rsync -r /srv/data gs://tenex/rails-assets/data &&
        curl -fsS --retry 3 https://hchk.io/d312c5e8-39f9-4382-8f7a-ed11706f4fbb
) &> "$log_dest"
