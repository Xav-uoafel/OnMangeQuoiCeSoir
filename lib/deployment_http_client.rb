require "net/http"
require "uri"

class DeploymentHttpClient
  Response = Data.define(:status, :headers, :body)

  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 10
  MAX_REDIRECTS = 3

  def call(uri)
    perform_request(uri, MAX_REDIRECTS)
  end

  private

  def perform_request(uri, redirects_remaining)
    response = execute(uri)
    return normalize(response) unless response.is_a?(Net::HTTPRedirection)

    follow_redirect(response, uri, redirects_remaining)
  end

  def execute(uri)
    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT
    ) { |http| http.request(request_for(uri)) }
  end

  def request_for(uri)
    Net::HTTP::Get.new(uri).tap do |request|
      request["Accept"] = "application/json, text/html;q=0.9, */*;q=0.8"
      request["User-Agent"] = "OnMangeQuoi-Staging-Smoke/1.0"
    end
  end

  def follow_redirect(response, uri, redirects_remaining)
    raise "trop de redirections" if redirects_remaining.zero?

    location = response["location"].to_s.strip
    raise "redirection sans destination" if location.empty?

    perform_request(URI.join(uri.to_s, location), redirects_remaining - 1)
  end

  def normalize(response)
    Response.new(
      status: response.code.to_i,
      headers: response.each_header.to_h.transform_keys(&:downcase),
      body: response.body.to_s
    )
  end
end
