require "test_helper"

class PwaControllerTest < ActionDispatch::IntegrationTest
  test "expose un manifeste installable avec des raccourcis mobiles" do
    get pwa_manifest_path(format: :json)

    assert_response :success
    assert_equal "OnMangeQuoi", response.parsed_body.fetch("name")
    assert_equal "standalone", response.parsed_body.fetch("display")
    assert_equal 2, response.parsed_body.fetch("icons").size
    assert_equal 3, response.parsed_body.fetch("shortcuts").size
  end

  test "expose un service worker qui ne met pas les pages authentifiees en cache" do
    get pwa_service_worker_path(format: :js)

    assert_response :success
    assert_includes response.body, "request.mode === \"navigate\""
    assert_includes response.body, "networkNavigation"
    assert_not_includes response.body, "cache.put(event.request"
  end

  test "affiche un ecran hors ligne autonome" do
    get offline_path

    assert_response :success
    assert_select "h1", "Le réseau fait une pause"
    assert_select "a[href='/']", "Réessayer"
  end
end
