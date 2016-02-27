module Support::ContinuousIntegration
  def self.upload_screenshot_on_failure?
    continuous_integration? && Support::Capybara.capybara_running?
  end

  def self.continuous_integration?
    ENV['CI'].present?
  end
end
