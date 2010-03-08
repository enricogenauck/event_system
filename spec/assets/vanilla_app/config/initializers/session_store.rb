# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_vanilla_app_session',
  :secret      => '7364b19aae8f40cb44c510de6f7b121ac99626f91f783cf8a696b6663d95212c6c9185a8a4f45d8480dc3d581b108c67958aa71dfc5f2bd7d2538809f76468a9'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
