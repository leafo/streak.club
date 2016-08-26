
import CloudStorage from require "cloud_storage.google"

oauth_stub = {
  client_email: "dad@streak.club"
  get_access_token: => "test-access-token"
  sign_string: (str) => "test-signature"
}

CloudStorage oauth_stub, "ACCOUNT"
