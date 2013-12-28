env :MAILTO, nil

every 1.hour do
  runner "UpdateScheduler.perform_async"
end

every 10.minutes do
  runner "Reindex.perform_async"
end
