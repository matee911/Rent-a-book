class Users < Application

#  def index
#    render
#  end

  def show(uid)
    @user = User.find_by_uid(uid)
    raise NotFound unless @user
    display @user
  end
end
