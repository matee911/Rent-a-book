class Users < Application

  def index
    page = params.delete(:page) || 1
    options = {:page => page, :per_page => 6, :order => 'full_name'}
    @users = User.paginate(options)
    display @users
  end

  def show(uid)
    @user = User.find_by_uid(uid)
    raise NotFound unless @user
    display @user
  end
end
