# template.rb
gem 'devise'
gem 'rails_admin'

gem_group :development, :test do
  gem "rspec-rails"
end

devise_model_name = ask("Qual o nome do modelo de usuário de autenticação? Exemplo: User, Admin, etc. Deixando em branco será utilizado o modelo User")
devise_model_name = "User" if devise_model_name.blank?


after_bundle do
  rails_command("generate rails_admin:install")
  rails_command("generate devise:install")
  rails_command("generate rspec:install")
  rails_command("generate devise #{devise_model_name}")
  rails_command("db:migrate")

  initializer 'rails_admin.rb', <<-CODE
    RailsAdmin.config do |config|
      config.authenticate_with do
        warden.authenticate! scope: :#{devise_model_name.downcase}
      end
      config.current_user_method(&:current_#{devise_model_name.downcase})
    end
  CODE
end
