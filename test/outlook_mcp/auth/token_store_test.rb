# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TokenStoreTest < Minitest::Test
  def setup
    @tmpfile = Tempfile.new("tokens")
    @config = OutlookMcp::Config.new
    @config.define_singleton_method(:token_path) { @tmpfile_path }
    @config.instance_variable_set(:@tmpfile_path, @tmpfile.path)
    @store = OutlookMcp::Auth::TokenStore.new(@config)
  end

  def teardown
    @tmpfile.close
    @tmpfile.unlink
  end

  def test_tokens_returns_nil_when_no_file
    @tmpfile.unlink
    config = OutlookMcp::Config.new
    config.define_singleton_method(:token_path) { "/nonexistent/path.json" }
    store = OutlookMcp::Auth::TokenStore.new(config)

    assert_nil store.tokens
  end

  def test_save_and_read_tokens
    @store.save({access_token: "abc123", refresh_token: "ref456", expires_in: 3600})

    data = @store.tokens
    assert_equal "abc123", data[:access_token]
    assert_equal "ref456", data[:refresh_token]
    assert data[:expires_at] > Time.now.to_i
  end

  def test_expired_returns_true_when_token_expired
    @store.save({access_token: "abc", expires_in: 0})
    # Manually set expires_at to the past
    data = JSON.parse(File.read(@tmpfile.path))
    data["expires_at"] = Time.now.to_i - 100
    File.write(@tmpfile.path, JSON.generate(data))

    assert @store.expired?
  end

  def test_expired_returns_false_when_token_valid
    @store.save({access_token: "abc", expires_in: 3600})

    refute @store.expired?
  end

  def test_access_token_returns_token_when_valid
    @store.save({access_token: "my-token", expires_in: 3600})

    assert_equal "my-token", @store.access_token
  end

  def test_access_token_raises_when_no_tokens
    @tmpfile.unlink
    config = OutlookMcp::Config.new
    config.define_singleton_method(:token_path) { "/nonexistent/path.json" }
    store = OutlookMcp::Auth::TokenStore.new(config)

    assert_raises(RuntimeError, "No tokens found") { store.access_token }
  end
end
