# template.rb
gem 'devise'
gem 'rails_admin'
gem 'cancancan'

gsub_file "Gemfile", /^gem\s+["']sqlite3["'].*$/,''

gem_group :development, :test do
  gem "rspec-rails"
  gem 'sqlite3', '~> 1.4'
  gem 'factory_bot_rails'
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

  insert_into_file "app/models/ability.rb", after: "def initialize(user)\n" do
    <<-CODE
    can :access, :rails_admin 
    can :read, :dashboard
    CODE
  end

  gsub_file "spec/rails_helper.rb", /# Dir/,'Dir'
  gsub_file "config/initializers/devise.rb", "# config.navigational_formats = ['*/*', :html]", "config.navigational_formats = ['*/*', :html, :turbo_stream]"
  gsub_file "config/initializers/devise.rb", '# config.sign_out_via = :delete', 'config.sign_out_via = :delete'

  create_file "spec/support/factory_bot.rb" do
    <<-CODE
    RSpec.configure do |config|
      config.include FactoryBot::Syntax::Methods
    end
    CODE
  end

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
