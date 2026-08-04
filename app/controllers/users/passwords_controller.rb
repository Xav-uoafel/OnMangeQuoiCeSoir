module Users
  class PasswordsController < Devise::PasswordsController
    def edit
      super

      token_owner = resource_class.with_reset_password_token(params[:reset_password_token])
      return if token_owner&.reset_password_period_valid?

      resource.errors.add(:reset_password_token, token_owner ? :expired : :invalid)
    end

    protected

    def after_sending_reset_password_instructions_path_for(resource_name)
      return "/dev/emails" if development_mailbox? && request.local?

      super
    end

    private

    def development_mailbox?
      Rails.env.development? && ActionMailer::Base.delivery_method == :letter_opener_web
    end
  end
end
