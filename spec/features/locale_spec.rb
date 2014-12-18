require 'spec_helper'

feature 'Suspend a new project with en as a locale param' do
  before :all do
    run_suspenders('--locale=en')
  end

  scenario 'generates en.yml' do
    expect(File).to exist("#{project_path}/config/locales/en.yml")
  end

  scenario 'does not inserts russian gem' do
    gemfile = IO.read("#{project_path}/Gemfile")

    expect(gemfile).not_to match(/gem 'russian'/)
  end
end
