# Be sure to restart your server when you modify this file.

#Tioj::Application.config.session_store :cookie_store, key: '_tioj_session'
Rails.application.config.session_store :active_record_store, key: '_tioj_session'
