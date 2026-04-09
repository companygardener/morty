Rails.application.routes.draw do
  mount Morty::Engine => "/morty"
end
