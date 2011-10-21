# -*- coding: utf-8 -*-
class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def ldap
    @user = User.find_for_ldap_auth(env['omniauth.auth'])

    if @user.persisted?
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', :kind => 'ldap'
      @user.remember_me = true
      sign_in_and_redirect @user, :event => :authentication
    else
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.failure', :kind => 'Ldap', :reason => 'User not found'
      redirect_to new_user_session_path
    end
  end

  def passthru
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end

end
