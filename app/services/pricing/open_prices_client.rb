# frozen_string_literal: true

require "faraday"
require "json"

module Pricing
  class OpenPricesClient
    BASE_URL = "https://prices.openfoodfacts.org/api/v1/"
    CACHE_TTL = 6.hours
    LOOKBACK_DAYS = 90
    PAGE_SIZE = 100

    def initialize(connection: nil, cache: Rails.cache, today: Date.current, force_refresh: false)
      @connection = connection || default_connection
      @cache = cache
      @today = today
      @force_refresh = force_refresh
    end

    def quote_for(category_tag:, preferred_price_units:)
      return if category_tag.blank? || preferred_price_units.blank?

      candidates = category_observations.select { |item| item["category_tag"] == category_tag }
      price_per = preferred_price_units.find do |unit|
        candidates.any? { |item| item["price_per"] == unit }
      end
      return unless price_per

      matching = candidates.select { |item| item["price_per"] == price_per }
      priced_observations = matching.filter_map do |item|
        price = normalized_price(item, price_per)
        [price, parse_date(item["date"])] if price
      end
      prices = priced_observations.map(&:first)
      return if prices.empty?

      {
        unit_price_cents: (robust_median(prices) * 100).round,
        price_per: price_per,
        observed_on: priced_observations.filter_map(&:last).max,
        sample_size: prices.size
      }
    end

    private

    def category_observations
      @category_observations ||= load_category_observations
    end

    def load_category_observations
      return [] unless integration_enabled?
      return @cache.fetch(cache_key, expires_in: CACHE_TTL) { fetch_category_observations } unless @force_refresh

      fresh_observations = fetch_category_observations
      @cache.write(cache_key, fresh_observations, expires_in: CACHE_TTL)
      fresh_observations
    end

    def fetch_category_observations
      response = @connection.get("prices", {
        type: "CATEGORY",
        currency: "EUR",
        date__gte: (@today - LOOKBACK_DAYS).iso8601,
        size: PAGE_SIZE,
        order_by: "-date"
      })

      Array(JSON.parse(response.body)["items"]).select { |item| eligible_observation?(item) }
    rescue Faraday::Error, JSON::ParserError => e
      status = e.response_status if e.respond_to?(:response_status)
      Rails.logger.warn "Open Prices unavailable: class=#{e.class} status=#{status}"
      []
    end

    def eligible_observation?(item)
      date = parse_date(item["date"])

      item.dig("location", "osm_address_country_code") == "FR" &&
        item["currency"] == "EUR" &&
        item["price_is_discounted"] == false &&
        item["duplicate_of"].nil? &&
        date.present? &&
        date.between?(@today - LOOKBACK_DAYS, @today)
    end

    def normalized_price(item, price_per)
      price = item["price"].to_f
      range = price_per == "KILOGRAM" ? (0.1..100.0) : (0.05..50.0)

      price if range.cover?(price)
    end

    def robust_median(values)
      median = median(values)
      filtered = values.select { |value| value.between?(median * 0.35, median * 2.85) }
      median(filtered.presence || values)
    end

    def median(values)
      sorted = values.sort
      middle = sorted.length / 2

      sorted.length.odd? ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2.0
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end

    def cache_key
      "open-prices/category-observations/v1/#{@today.iso8601}"
    end

    def integration_enabled?
      ENV.fetch("OPEN_PRICES_ENABLED", "true") != "false"
    end

    def default_connection
      Faraday.new(url: ENV.fetch("OPEN_PRICES_API_URL", BASE_URL)) do |connection|
        connection.headers["User-Agent"] = ENV.fetch("OPEN_PRICES_USER_AGENT", "OnMangeQuoiCeSoir/1.0")
        connection.options.open_timeout = 2
        connection.options.timeout = 6
        connection.response :raise_error
        connection.adapter Faraday.default_adapter
      end
    end
  end
end
