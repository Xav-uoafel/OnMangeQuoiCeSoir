require "test_helper"

class Pricing::OpenPricesClientTest < ActiveSupport::TestCase
  Response = Struct.new(:body)

  class FakeConnection
    attr_reader :path, :params

    def initialize(payload)
      @payload = payload
    end

    def get(path, params)
      @path = path
      @params = params
      Response.new(@payload.to_json)
    end
  end

  test "uses the median of recent non-discounted French observations" do
    today = Date.new(2026, 7, 11)
    connection = FakeConnection.new(items: [
      observation(price: 2.0, date: "2026-07-01"),
      observation(price: 4.0, date: "2026-07-10"),
      observation(price: 20.0, date: "2026-07-10", country: "BE"),
      observation(price: 1.0, date: "2026-07-10", discounted: true)
    ])
    client = Pricing::OpenPricesClient.new(connection: connection, cache: ActiveSupport::Cache::NullStore.new, today: today)

    quote = client.quote_for(category_tag: "en:tomatoes", preferred_price_units: ["KILOGRAM"])

    assert_equal 300, quote[:unit_price_cents]
    assert_equal "KILOGRAM", quote[:price_per]
    assert_equal Date.new(2026, 7, 10), quote[:observed_on]
    assert_equal 2, quote[:sample_size]
    assert_equal "prices", connection.path
    assert_equal "EUR", connection.params[:currency]
    assert_equal "2026-04-12", connection.params[:date__gte]
  end

  private

  def observation(price:, date:, country: "FR", discounted: false)
    {
      "category_tag" => "en:tomatoes",
      "currency" => "EUR",
      "date" => date,
      "duplicate_of" => nil,
      "location" => { "osm_address_country_code" => country },
      "price" => price,
      "price_is_discounted" => discounted,
      "price_per" => "KILOGRAM"
    }
  end
end
