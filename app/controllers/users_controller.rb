class UsersController < ApplicationController
  before_action :signed_in_user, only:[:edit, :update, :index]
  before_action :not_signed_in_user, only:[:new, :create]
  before_action :correct_user, only:[:edit, :update]
  before_action :admin_user, only: :destroy
  before_action :different_user, only: :destroy

  def show
  	@user = User.find(params[:id])
    @microposts = @user.microposts.paginate(page: params[:page])
  end

  def index
    @users = User.paginate(page: params[:page])
  end
  
  def new
  	@user = User.new
  end
  
  def create
  	@user = User.new(params[:user])
  	if @user.save
		flash[:success] = "Welcome to the Sample App!"
		sign_in @user
		redirect_to @user
  	else
  		render 'new'
  	end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User destroyed."
    redirect_to users_url
  end


  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      flash[:success] = "Profile updated"
      sign_in @user
      redirect_to @user
    else
      render 'edit'
    end      
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    # Before filters
    def signed_in_user
      unless signed_in?
        store_location
        redirect_to signin_url, notice: "Please sign in."
      end
    end

    def not_signed_in_user
      unless !signed_in?
        redirect_to(root_url) and return
      end  
    end

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end

    def different_user
      #Confirm that the signed in user is not the one about to be destroyed
      @user = User.find(params[:id])
      redirect_to(root_url) unless !current_user?(@user)
    end

    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end
end
