require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "reports that the application and database are ready" do
    get readiness_check_path

    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_equal({ "status" => "ok", "checks" => { "database" => "up" } }, response.parsed_body)
  end

  test "reports an unavailable database without exposing the exception" do
    original_check = HealthController.database_check
    HealthController.database_check = -> { raise ActiveRecord::ConnectionNotEstablished, "database secret" }

    begin
      get readiness_check_path
    ensure
      HealthController.database_check = original_check
    end

    assert_response :service_unavailable
    assert_equal({ "status" => "unavailable", "checks" => { "database" => "down" } }, response.parsed_body)
    assert_not_includes response.body, "database secret"
  end
end
