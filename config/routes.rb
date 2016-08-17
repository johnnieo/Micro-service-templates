TemplateService::Application.routes.draw do
  root to: redirect('/status')

  namespace :v1, format: :json do
  end
end
