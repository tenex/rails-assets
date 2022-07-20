#!/bin/zsh
(
    /usr/bin/gsutil -m cp -n /var/log/nginx/*.gz gs://tenex/rails-assets/logs/nginx/ &&
        curl -fsS --retry 3 https://hchk.io/37b06c55-960d-43fd-8a9d-a40eb2a5b661
) &> $HOME/log-backup.log
