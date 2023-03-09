class JsonWebToken

  def self.encode(payload)
    return JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end

  def self.decode(token)
    Rails.logger.debug "validating JWT"
    return JWT.decode(token, Rails.application.secrets.secret_key_base)
  rescue
    nil
  end
end