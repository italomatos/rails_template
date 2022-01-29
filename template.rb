# template.rb
gem 'devise'
gem 'rails_admin'
gem 'cancancan'

gsub_file "Gemfile", /^gem\s+["']sqlite3["'].*$/,''

gem_group :development, :test do
  gem "rspec-rails"
  gem 'sqlite3', '~> 1.4'
end

gem_group :production do
  gem "pg"
end

devise_model_name = ask("Qual o nome do modelo de usuário de autenticação? Exemplo: User, Admin, etc. Deixando em branco será utilizado o modelo User")
devise_model_name = "User" if devise_model_name.blank?


after_bundle do
  rails_command("generate rails_admin:install")
  rails_command("generate devise:install")
  rails_command("generate rspec:install")
  rails_command("generate cancan:ability")
  rails_command("generate devise #{devise_model_name}")
  rails_command("db:migrate")

  initializer 'rails_admin.rb', <<-CODE
    RailsAdmin.config do |config|
      config.authenticate_with do
        warden.authenticate! scope: :#{devise_model_name.downcase}
      end
      config.current_user_method(&:current_#{devise_model_name.downcase})
      config.authorize_with :cancancan
    end
  CODE

  insert_into_file "app/models/ability.rb", "\n  can :access, :rails_admin \n  can :read, :dashboard \n", after: "def initialize(user)"
    


  git :init
  git add: "."
  git commit: "-m 'First commit!'"

  if yes?("Publicar no Heroku?")
    run "bundle lock --add-platform x86_64-linux"
    git add: "."
    git commit: "-m 'bundle lock --add-platform x86_64-linux'"
    run "heroku create" 
    run "git push heroku master" 
    run "heroku run rails db:migrate" 
  end
end
