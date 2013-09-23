web: bin/thin start -p $PORT
sidekiq: bin/sidekiq -q update_scheduler -q update_component -q default -q reindex
