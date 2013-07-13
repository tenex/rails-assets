web: bin/thin start -p $PORT
#web: bin/puma -p $PORT
sidekiq: bin/sidekiq -r ./lib/rails/assets -q reindex -q update
