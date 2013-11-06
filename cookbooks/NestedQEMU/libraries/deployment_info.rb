module DeploymentInfo

  def get_file_source(file_name)
    get_user_id ? "user#{get_user_id}/#{file_name}" : file_name
  end

  def get_user_id(name = node.name)
    /-user-(\d+)-topology-/.match(name)[1]
  end

  def get_topology_name(name = node.name)
    /-topology-(\w+)-node-/.match(name)[1]
  end

  def get_node_shortname(name = node.name)
    /-node-([\w-]+)$/.match(name)[1]
  end

  def get_node_rank(name = node.name)
    name.split("-").last
  end

end