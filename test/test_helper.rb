# frozen_string_literal: true

require "minitest/autorun"
require "minitest/reporters"
require "webmock/minitest"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

ENV["OUTLOOK_CLIENT_ID"] ||= "test-client-id"
ENV["OUTLOOK_CLIENT_SECRET"] ||= "test-client-secret"
ENV["OUTLOOK_TENANT_ID"] ||= "test-tenant"

require_relative "../lib/outlook_mcp"

OutlookMcp.eager_load!
