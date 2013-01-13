module InstallationHelpers
  def chef_server?
    %w{NestedQEMU::standalone_installation NestedQEMU::server_installation}.any? do |recipe| 
      node.recipes.include?(recipe)
    end
  end
end