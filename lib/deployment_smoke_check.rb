require "json"
require "uri"
require_relative "deployment_http_client"

class DeploymentSmokeCheck
  Result = Data.define(:name, :success, :message) do
    def success?
      success
    end
  end

  Response = DeploymentHttpClient::Response

  def initialize(base_url:, requester: nil)
    @base_uri = parse_base_url(base_url)
    @requester = requester || DeploymentHttpClient.new
  end

  def call
    [
      check_status_endpoint("/up", "Rails"),
      check_health,
      check_home,
      check_manifest,
      check_service_worker
    ]
  end

  private

  attr_reader :base_uri, :requester

  def check_status_endpoint(path, label)
    safely("#{label} #{path}") do
      response = request(path)
      assert_status!(response, 200)
      "HTTP 200"
    end
  end

  def check_health
    safely("Readiness /health") do
      response = request("/health")
      assert_status!(response, 200)
      payload = JSON.parse(response.body)

      unless payload["status"] == "ok" && payload.dig("checks", "database") == "up"
        raise "réponse inattendue : #{payload.inspect}"
      end

      "application et PostgreSQL disponibles"
    end
  end

  def check_home
    safely("Page publique et sécurité") do
      response = request("/")
      assert_status!(response, 200)

      required_headers = %w[content-security-policy permissions-policy x-content-type-options]
      required_headers << "strict-transport-security" if base_uri.scheme == "https"
      missing_headers = required_headers.select { |name| response.headers[name].to_s.strip == "" }
      raise "en-têtes absents : #{missing_headers.join(', ')}" if missing_headers.any?

      "HTTP 200 et en-têtes de sécurité présents"
    end
  end

  def check_manifest
    safely("PWA /manifest.json") do
      response = request("/manifest.json")
      assert_status!(response, 200)
      payload = JSON.parse(response.body)
      required_keys = %w[name short_name start_url display]
      missing_keys = required_keys.select { |key| payload[key].to_s.strip == "" }
      raise "clés absentes : #{missing_keys.join(', ')}" if missing_keys.any?

      "manifeste valide"
    end
  end

  def check_service_worker
    safely("PWA /service-worker.js") do
      response = request("/service-worker.js")
      assert_status!(response, 200)
      content_type = response.headers["content-type"].to_s
      raise "type de contenu inattendu : #{content_type.inspect}" unless content_type.include?("javascript")

      "service worker disponible"
    end
  end

  def safely(name)
    Result.new(name: name, success: true, message: yield)
  rescue StandardError => e
    Result.new(name: name, success: false, message: e.message)
  end

  def request(path)
    requester.call(endpoint(path))
  end

  def endpoint(path)
    uri = base_uri.dup
    uri.path = path
    uri.query = nil
    uri.fragment = nil
    uri
  end

  def assert_status!(response, expected)
    return if response.status == expected

    raise "HTTP #{response.status}, attendu #{expected}"
  end

  def parse_base_url(value)
    uri = URI.parse(value.to_s.strip)
    unless uri.is_a?(URI::HTTP) && !uri.host.to_s.empty?
      raise ArgumentError, "STAGING_URL doit être une URL HTTP(S) complète"
    end

    uri
  rescue URI::InvalidURIError
    raise ArgumentError, "STAGING_URL doit être une URL HTTP(S) complète"
  end
end
