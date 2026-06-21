# frozen_string_literal: true
require "test_helper"
require "yaml"
require "erb"

class RecurringScheduleTest < ActiveSupport::TestCase
  def setup
    @config_path = Rails.root.join("config", "recurring.yml")
    @raw_yaml    = ERB.new(File.read(@config_path)).result
    @config      = YAML.safe_load(@raw_yaml, aliases: true)
  end

  # --- recurring configuration exists ---

  test "recurring.yml exists" do
    assert File.exist?(@config_path), "Expected config/recurring.yml to exist"
  end

  test "recurring.yml parses as valid YAML" do
    assert_kind_of Hash, @config
  end

  test "recurring.yml defines configuration for the development environment" do
    assert @config.key?("development"), "Expected a development environment block"
  end

  test "recurring.yml defines configuration for the production environment" do
    assert @config.key?("production"), "Expected a production environment block"
  end

  # --- GenerateDailyProfitsJob is scheduled ---

  test "GenerateDailyProfitsJob is present in the development schedule" do
    entries = @config["development"].values
    classes = entries.map { |entry| entry["class"] }
    assert_includes classes, "GenerateDailyProfitsJob"
  end

  test "GenerateDailyProfitsJob is present in the production schedule" do
    entries = @config["production"].values
    classes = entries.map { |entry| entry["class"] }
    assert_includes classes, "GenerateDailyProfitsJob"
  end

  test "GenerateDailyProfitsJob entry has a schedule defined" do
    entry = find_entry_for("GenerateDailyProfitsJob", environment: "development")
    assert entry.present?
    assert entry["schedule"].present?
  end

  # --- CompleteInvestmentsJob is scheduled ---

  test "CompleteInvestmentsJob is present in the development schedule" do
    entries = @config["development"].values
    classes = entries.map { |entry| entry["class"] }
    assert_includes classes, "CompleteInvestmentsJob"
  end

  test "CompleteInvestmentsJob is present in the production schedule" do
    entries = @config["production"].values
    classes = entries.map { |entry| entry["class"] }
    assert_includes classes, "CompleteInvestmentsJob"
  end

  test "CompleteInvestmentsJob entry has a schedule defined" do
    entry = find_entry_for("CompleteInvestmentsJob", environment: "development")
    assert entry.present?
    assert entry["schedule"].present?
  end

  # --- scheduling layer references correct, existing job classes ---

  test "GenerateDailyProfitsJob referenced in recurring.yml is a real, loadable job class" do
    assert defined?(GenerateDailyProfitsJob), "GenerateDailyProfitsJob must be a defined constant"
    assert GenerateDailyProfitsJob < ApplicationJob
  end

  test "CompleteInvestmentsJob referenced in recurring.yml is a real, loadable job class" do
    assert defined?(CompleteInvestmentsJob), "CompleteInvestmentsJob must be a defined constant"
    assert CompleteInvestmentsJob < ApplicationJob
  end

  test "every entry in the development schedule references a class that responds to perform_later" do
    @config["development"].each_value do |entry|
      job_class = entry["class"].constantize
      assert_respond_to job_class, :perform_later
    end
  end

  test "every entry in the production schedule references a class that responds to perform_later" do
    @config["production"].each_value do |entry|
      job_class = entry["class"].constantize
      assert_respond_to job_class, :perform_later
    end
  end

  # --- scheduler does not duplicate business logic ---

  test "recurring.yml contains no investment, profit, or wallet keys beyond class and schedule" do
    allowed_keys = %w[class schedule queue priority args]
    @config["development"].each_value do |entry|
      entry.keys.each do |key|
        assert_includes allowed_keys, key,
                        "Unexpected key '#{key}' found in recurring.yml — scheduling config should only enqueue jobs"
      end
    end
  end

  private

  def find_entry_for(class_name, environment:)
    @config[environment].values.find { |entry| entry["class"] == class_name }
  end
end
