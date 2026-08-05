require "test_helper"
require "nokogiri"
require "uri"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    ActionMailer::Base.deliveries.clear
  end

  teardown do
    ActionMailer::Base.deliveries.clear
  end

  test "reset email contains a link that changes the password" do
    user = users(:one)

    assert_emails 1 do
      post user_password_path, params: { user: { email: user.email } }
    end

    assert_redirected_to new_user_session_path

    email = ActionMailer::Base.deliveries.last
    assert_equal [user.email], email.to
    assert_equal I18n.t("devise.mailer.reset_password_instructions.subject"), email.subject

    reset_url = reset_link_from(email)
    assert_equal "example.com", reset_url.host

    reset_token = Rack::Utils.parse_query(reset_url.query).fetch("reset_password_token")
    get edit_user_password_path(reset_password_token: reset_token)
    assert_response :success

    new_password = "new-password123"
    patch user_password_path, params: {
      user: {
        reset_password_token: reset_token,
        password: new_password,
        password_confirmation: new_password
      }
    }

    assert_response :redirect
    assert user.reload.valid_password?(new_password)
  end

  test "unknown email gets the same redirect without sending a message" do
    assert_no_emails do
      post user_password_path, params: { user: { email: "unknown@example.com" } }
    end

    assert_redirected_to new_user_session_path
    assert_equal I18n.t("devise.passwords.send_paranoid_instructions"), flash[:notice]
  end

  test "expired reset token offers a new link when the page opens" do
    user = users(:one)
    reset_token = expired_reset_token_for(user)

    get edit_user_password_path(reset_password_token: reset_token)

    assert_response :success
    assert_select "h1", text: "Ce lien a expiré"
    assert_select "a[href='#{new_user_password_path}']", text: "Recevoir un nouveau lien"
    assert_select "input[type='password']", count: 0
    assert_no_match(/Translation missing/, response.body)
  end

  test "expired reset token cannot change the password" do
    user = users(:one)
    reset_token = expired_reset_token_for(user)

    patch user_password_path, params: {
      user: {
        reset_password_token: reset_token,
        password: "new-password123",
        password_confirmation: "new-password123"
      }
    }

    assert_response :unprocessable_entity
    assert_select "h1", text: "Ce lien a expiré"
    assert_select "a[href='#{new_user_password_path}']", text: "Recevoir un nouveau lien"
    assert_select "input[type='password']", count: 0
    assert_no_match(/Translation missing/, response.body)
    assert_not user.reload.valid_password?("new-password123")
  end

  test "invalid reset token offers a new link" do
    get edit_user_password_path(reset_password_token: "invalid-token")

    assert_response :success
    assert_select "h1", text: "Ce lien n’est plus valide"
    assert_select "a[href='#{new_user_password_path}']", text: "Recevoir un nouveau lien"
    assert_select "input[type='password']", count: 0
  end

  private

  def reset_link_from(email)
    document = Nokogiri::HTML(email.html_part.body.decoded)
    URI.parse(document.at_css('a[href*="reset_password_token"]')["href"])
  end

  def expired_reset_token_for(user)
    assert_emails 1 do
      post user_password_path, params: { user: { email: user.email } }
    end

    reset_url = reset_link_from(ActionMailer::Base.deliveries.last)
    user.update!(reset_password_sent_at: 7.hours.ago)
    Rack::Utils.parse_query(reset_url.query).fetch("reset_password_token")
  end
end
