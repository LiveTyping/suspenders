require 'spec_helper'

feature 'Suspend a new project with default configuration' do
  before :all do
    run_suspenders
  end

  scenario 'specs pass' do
    Dir.chdir(project_path) do
      Bundler.with_clean_env do
        expect(`rake`).to include('0 failures')
      end
    end
  end

  scenario 'staging config is inherited from production' do
    staging_file = IO.read("#{project_path}/config/environments/staging.rb")
    config_stub = "Rails.application.configure do"

    expect(staging_file).to match(/^require_relative 'production'/)
    expect(staging_file).to match(/#{config_stub}/), staging_file
  end

  scenario 'generated .ruby-version is pulled from Suspenders .ruby-version' do
    ruby_version_file = IO.read("#{project_path}/.ruby-version")

    expect(ruby_version_file).to eq "#{RUBY_VERSION}\n"
  end

  scenario 'secrets.yml reads secret from env' do
    secrets_file = IO.read("#{project_path}/config/secrets.yml")

    expect(secrets_file).to match(/secret_key_base: <%= ENV\['SECRET_KEY_BASE'\] %>/)
  end

  scenario 'action mailer support file is added' do
    expect(File).to exist("#{project_path}/spec/support/action_mailer.rb")
  end

  scenario "i18n support file is added" do
    expect(File).to exist("#{project_path}/spec/support/i18n.rb")
  end

  scenario 'figaro gem is configured' do
    expect(File).to exist("#{project_path}/config/application.example.yml")

    application_yml_file = IO.read("#{project_path}/config/application.yml")

    expect(application_yml_file).to match(/SECRET_KEY_BASE: \S+/)
  end

  scenario 'newrelic.yml reads NewRelic license from env' do
    newrelic_file = IO.read("#{project_path}/config/newrelic.yml")

    expect(newrelic_file).to match(
      /license_key: "<%= ENV\['NEW_RELIC_LICENSE_KEY'\] %>"/
    )
  end

  scenario "raises on missing translations in development and test" do
    %w[development test].each do |environment|
      environment_file =
        IO.read("#{project_path}/config/environments/#{environment}.rb")
      expect(environment_file).to match(
        /^ +config.action_view.raise_on_missing_translations = true$/
      )
    end
  end

  scenario 'installs annotate' do
    expect(File).to exist("#{project_path}/lib/tasks/auto_annotate_models.rake")

    expect(gemfile).to match(/gem 'annotate'/)
  end

  scenario "specs for missing or unused translations" do
    expect(File).to exist("#{project_path}/spec/i18n_spec.rb")
  end

  scenario "config file for i18n tasks" do
    expect(File).to exist("#{project_path}/config/i18n-tasks.yml")
  end

  scenario "generated ru.yml and inserted gem russian" do
    expect(File).not_to exist("#{project_path}/config/locales/en.yml")
    expect(File).to exist("#{project_path}/config/locales/ru.yml")

    locales_file = IO.read("#{project_path}/config/locales/ru.yml")
    app_name = SuspendersTestHelpers::APP_NAME

    expect(locales_file).to match(/application: #{app_name.humanize}/)

    expect(gemfile).to match(/gem 'russian'/)
  end

  scenario "config simple_form" do
    expect(File).to exist("#{project_path}/config/initializers/simple_form.rb")
  end

  scenario "config :test email delivery method for development" do
    dev_env_file = IO.read("#{project_path}/config/environments/development.rb")
    expect(dev_env_file).
      to match(/^ +config.action_mailer.delivery_method = :test$/)
  end

  def gemfile
    @gemfile ||= IO.read("#{project_path}/Gemfile")
  end
end
