env :MAILTO, nil

every 12.hours, roles: [:db] do
  runner 'UpdateScheduler.perform_async'
end
