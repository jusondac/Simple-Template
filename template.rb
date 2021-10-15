def add_template_to_source_path

end
# Main setup
add_template_to_source_path
add_gems

after_bundle do
  set_application_name
  setup_bootstrap
  setup_users
  setup_table
  usually_add_home
  copy_templates
  say
  puts "\u{1f355} Team mate up!!!"
  say
  say 'To get started with your new app:', :green
  say "cd #{app_name} - Switch to your new app's directory."
end
