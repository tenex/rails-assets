#!/bin/zsh
(
    /usr/bin/pg_dump --format=custom --username=rails_assets rails_assets_production |
        bzip2 |
        /usr/bin/gsutil cp - gs://tenex-database-backups/rails-assets-production.dump.bz2 &&
        curl -fsS --retry 3 https://hchk.io/aed419a9-4fa1-4741-9847-b6620804776f
) &> $HOME/database-backup.log
