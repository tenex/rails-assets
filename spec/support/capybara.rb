module Support::Capybara
  def self.capybara_running?
    Capybara.current_session.driver.browser_initialized?
  end

  def self.save_screenshot
    image_path = Capybara.save_screenshot
    puts "Capybara screenshot saved at #{image_path}"
  end

  def self.upload_screenshot
    image_path = Capybara.save_screenshot
    # filename = image_path.split('/').last
    response = `curl https://uguu.se/api.php?d=upload -F file=@#{image_path}`
    puts "Capybara screenshot available at #{response}"
  end
end
