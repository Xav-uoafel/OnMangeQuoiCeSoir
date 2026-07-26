require "test_helper"
require Rails.root.join("lib/deployment_smoke_check")

class DeploymentSmokeCheckTest < ActiveSupport::TestCase
  test "accepts a healthy deployment" do
    results = checker.call

    assert results.all?(&:success?)
    assert_equal 5, results.size
  end

  test "reports an unavailable database" do
    responses["/health"] = response(
      body: { status: "degraded", checks: { database: "down" } }.to_json
    )

    result = checker.call.find { |item| item.name == "Readiness /health" }

    assert_not result.success?
    assert_includes result.message, "réponse inattendue"
  end

  test "reports missing security headers" do
    responses["/"] = response(headers: { "content-type" => "text/html" })

    result = checker.call.find { |item| item.name == "Page publique et sécurité" }

    assert_not result.success?
    assert_includes result.message, "content-security-policy"
    assert_includes result.message, "strict-transport-security"
  end

  test "reports network errors without aborting other checks" do
    requester = lambda do |uri|
      raise SocketError, "hôte introuvable" if uri.path == "/health"

      responses.fetch(uri.path)
    end

    results = DeploymentSmokeCheck.new(base_url: "https://staging.example.com", requester: requester).call

    assert_equal 4, results.count(&:success?)
    assert_equal "hôte introuvable", results.reject(&:success?).first.message
  end

  test "rejects an incomplete staging URL" do
    assert_raises(ArgumentError) do
      DeploymentSmokeCheck.new(base_url: "staging.example.com")
    end
  end

  private

  def checker
    DeploymentSmokeCheck.new(
      base_url: "https://staging.example.com",
      requester: ->(uri) { responses.fetch(uri.path) }
    )
  end

  def responses
    @responses ||= {
      "/up" => response(body: "<html>OK</html>"),
      "/health" => response(body: { status: "ok", checks: { database: "up" } }.to_json),
      "/" => home_response,
      "/manifest.json" => manifest_response,
      "/service-worker.js" => service_worker_response
    }
  end

  def home_response
    response(
      body: "<html>OnMangeQuoi</html>",
      headers: {
        "content-security-policy" => "default-src 'self'",
        "permissions-policy" => "camera=()",
        "strict-transport-security" => "max-age=63072000",
        "x-content-type-options" => "nosniff"
      }
    )
  end

  def manifest_response
    response(
      body: { name: "OnMangeQuoi", short_name: "OMQ", start_url: "/", display: "standalone" }.to_json,
      headers: { "content-type" => "application/json" }
    )
  end

  def service_worker_response
    response(
      body: "self.addEventListener('install', () => {});",
      headers: { "content-type" => "text/javascript" }
    )
  end

  def response(body: "", status: 200, headers: {})
    DeploymentSmokeCheck::Response.new(status: status, headers: headers, body: body)
  end
end
