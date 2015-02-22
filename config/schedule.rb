env :MAILTO, nil

every 3.hours do
  runner "UpdateScheduler.perform_async"
end
