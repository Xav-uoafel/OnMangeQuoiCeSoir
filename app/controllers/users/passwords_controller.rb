module Users
  class PasswordsController < Devise::PasswordsController
    protected

    def after_sending_reset_password_instructions_path_for(resource_name)
      return "/dev/emails" if development_mailbox?

      super
    end

    private

    def development_mailbox?
      Rails.env.development? && ActionMailer::Base.delivery_method == :letter_opener_web
    end
  end
end
