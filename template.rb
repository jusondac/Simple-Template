=begin
Template Name: Simple Template
Author: Rejka Permana
Instructions: $ rails new myapp -d <postgresql, mysql, sqlite> -m template.rb
=end

require 'fileutils'
require 'shellwords'

def add_template_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require 'tmpdir'
    source_paths.unshift(tempdir = Dir.mktmpdir('Simple-Template-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      '--quiet',
      'https://github.com/jusondac/Simple-Template.git',
      tempdir
    ].map(&:shellescape).join(' ')
    if (branch = __FILE__[%r{Simple-Template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def rails_version
  @rails_version ||= Gem::Version.new(Rails::VERSION::STRING)
end

def add_gems
  gem 'awesome_print'
  gem 'devise'
end

def set_application_name
  environment 'config.application_name = Rails.application.class.module_parent_name'
  puts 'You can change application name inside: ./config/application.rb'
end

def setup_bootstrap
  run 'yarn add bootstrap jquery popper.js'

  # Update environment.js
  bootstrap_conf = <<-CODE
const webpack = require('webpack')
environment.plugins.append('Provide',new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery',
  Popper: ['popper.js', 'default']
}))
  CODE

  insert_into_file "config/webpack/environment.js",  bootstrap_conf , before: "module.exports = environment"

  # Update application.js
  inject_into_file 'app/javascript/packs/application.js', after: '// const imagePath = (name) => images(name, true)' do
    "\nimport 'bootstrap'"
  end
  # Update css file
  inject_into_file 'app/assets/stylesheets/application.css', before:'*= require_tree .' do
    "*= require bootstrap\n "
  end
  # adding custom css file
  app_scss = 'app/assets/stylesheets/custom.css.scss'
  FileUtils.touch(app_scss)
  append_to_file app_scss do
    "@import 'bootstrap/scss/bootstrap';\n"
  end
end

def setup_users
  # Install Devise
  generate 'devise:install'

  # Configure Devise
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'

  content = <<-CODE
unauthenticated :user do
  devise_scope :user do
    root to: 'unauthenticated#index', as: :unauthenticated_root
  end
end

authenticated :user do
  root to: 'home#index', as: :authenticated_root
end
  CODE

  # Generate Devise views via Bootstrap
  generate 'devise:views'

   # Create Devise User
  generate :devise, 'User', 'first_name', 'last_name', 'role_id:integer'
  insert_into_file "config/routes.rb", "\n" + content + "\n", after: "Rails.application.routes.draw do"
  if Gem::Requirement.new("> 5.2").satisfied_by? rails_version
    gsub_file 'config/initializers/devise.rb',
      /  # config.secret_key = .+/,
      '  config.secret_key = Rails.application.credentials.secret_key_base'
  end
  rails_command 'db:migrate'
end

def setup_table
  generate(:model, 'role name:string')
  inject_into_file 'db/seed.rb', after: '#   Character.create(name: "Luke", movie: movies.first)' do
    role = ['master','admin','user']
    role.each do |role_name|
      Role.create(name:role_name)
    end
  end
  rails_command 'db:migrate'
end

def add_home_page
  generate(:controller, "home index")
  route "root to:'home#index'"
end

def copy_templates
  directory 'app', force: true
end

# Main setup
add_template_to_source_path
add_gems

after_bundle do
  set_application_name

  setup_bootstrap
  setup_users
  setup_table
  
  add_home_page
  copy_templates

  puts ""
  puts "Your app finnaly done create!! \u{1f355} 🎉 \n"
  puts 'To get started with your new app: \n'
  puts "cd #{app_name} - Switch to your new app's directory."
end
