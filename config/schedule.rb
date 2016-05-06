env :MAILTO, nil

every 3.hours, roles: [:db] do
  runner 'UpdateScheduler.perform_async'
end
