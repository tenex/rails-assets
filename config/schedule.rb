env :MAILTO, nil

every 24.hours, roles: [:db] do
  runner 'UpdateScheduler.perform_async'
end
