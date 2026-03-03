# frozen_string_literal: true

class Rack::Attack
  # Throttle login attempts by IP: 20 requests per minute
  throttle("logins/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # Throttle login attempts by email: 10 requests per minute per email address
  throttle("logins/email", limit: 10, period: 1.minute) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email").to_s.downcase.strip.presence
    end
  end

  # Throttle registration attempts by IP: 5 per hour
  throttle("registrations/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/users" && req.post?
  end

  # Throttle password reset requests by IP: 5 per hour
  throttle("password_resets/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/users/password" && req.post?
  end

  # Throttle password reset requests by email: 5 per hour
  throttle("password_resets/email", limit: 5, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.params.dig("user", "email").to_s.downcase.strip.presence
    end
  end

  # Throttle investment price refresh per user: 10 per hour
  throttle("refresh_prices/user", limit: 10, period: 1.hour) do |req|
    if req.post? && req.path.match?(%r{\A/investments(/\d+/refresh_price|/refresh_all_prices)\z})
      req.env["warden"]&.user&.id
    end
  end

  # Return 429 with a plain message when throttled
  self.throttled_responder = lambda do |_env|
    [
      429,
      { "content-type" => "text/plain" },
      [ "Too many requests. Please try again later." ]
    ]
  end
end
