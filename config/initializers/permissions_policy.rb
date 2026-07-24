# Be sure to restart your server when you modify this file.

# Define an application-wide HTTP permissions policy. For further
# information see: https://developers.google.com/web/updates/2018/06/feature-policy

Rails.application.config.action_dispatch.default_headers.merge!(
  "Permissions-Policy" => [
    "camera=(self)",
    "geolocation=()",
    "gyroscope=()",
    "microphone=()",
    "payment=()",
    "usb=()"
  ].join(", ")
)
