env :MAILTO, nil

every 3.hours, roles: [:worker] do
  runner 'UpdateScheduler.perform_async'
end
