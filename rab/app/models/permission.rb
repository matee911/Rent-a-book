class Permission
  include MongoMapper::EmbeddedDocument
  
  key :name, String
  key :obj_type, String
  key :obj_id, String
  
  def ==(another_permission)
    if another_permission.class == self.class
      return (another_permission.name == self.name && another_permission.obj_type == self.obj_type && another_permission.obj_id == self.obj_id)
    end
    false
  end
  
  class << self
    def build_permission(permission_name, obj = nil)
      permission = Permission.new(:name => permission_name)
      if obj.is_a? String
        # jesli przekazany string to znaczy ze dla klasy ustawiamy permission
        # implikuje to niemozliwosc ustawienia permisiiona dla obiektu klasy String
        # ale to nas chyba nie boli :P
        permission.obj_type = obj
      elsif !obj.nil?
        permission.obj_type = obj.class.to_s
        permission.obj_id = obj.id
      end
      return permission
    end
  end
  
end