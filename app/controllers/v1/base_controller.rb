class V1::BaseController < ApplicationController
  prepend_before_action :set_cors_headers, :authenticate

  def cors
    head :ok
  end

  private

  def allow_origins
    @allow_origins ||= ENV['CORS_ALLOWED_ORIGINS'].to_s.split(/\s*\|\s*/)
  end

  def authenticate
    head :forbidden if request.headers['X-SSL-Auth'].blank? || !current_certificate.verify(public_key)
  end

  def current_certificate
    @current_certificate ||= OpenSSL::X509::Certificate.new(CGI.unescape(request.headers['X-SSL-Auth']))
  end

  def current_client
    current_certificate.issuer.to_a.assoc('OU')[1]
  end

  def public_key
    @public_key ||= begin
      public_key = ENV['AUTH_PUBLIC_KEY']
      public_key = CGI.unescape(public_key) if public_key =~ /%/
      OpenSSL::PKey::RSA.new(public_key)
    end
  end

  def set_cors_headers
    if allow_origins.present? && allow_origins.first == 'star'
      headers['Access-Control-Allow-Origin'] = '*'
    elsif (origin_by_ip = request.headers['HTTP_ORIGIN'].to_s) =~ %r[^http://(?:[0-9]{1,3}\.){3}[0-9]{1,3}$] &&
        allow_origins.detect { |o| o =~ /^(?:[0-9]{1,3}\.)/ && origin_by_ip =~ %r{^http://#{o}\.} }
      headers['Access-Control-Allow-Origin'] = origin_by_ip
    elsif (origin = URI(request.headers['HTTP_ORIGIN'].to_s).host).present? &&
        allow_origins.detect { |o| origin =~ /\.#{o}$/i }
      headers['Access-Control-Allow-Origin'] = request.headers['HTTP_ORIGIN']
    end

    headers['Access-Control-Allow-Methods'] = ENV['CORS_METHODS'].presence || 'POST,GET,OPTIONS,DELETE,PUT'
    headers['Access-Control-Allow-Headers'] = ENV['CORS_HEADERS'].presence ||
      'Accept,Content-Type,X-Requested-With,X-Johnio-Access-Token'
    headers['Access-Control-Max-Age'] = '86400'
  end
end
