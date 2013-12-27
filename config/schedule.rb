every 1.hour do
  runner "UpdateScheduler.perform_async"
end
