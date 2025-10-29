class Buttons::DeleteButtonComponent < Buttons::ButtonComponent
  def initialize(path:, text: "Delete", icon: "trash")
    super(path: path, text: text, icon: icon, color: "red")
  end
end
