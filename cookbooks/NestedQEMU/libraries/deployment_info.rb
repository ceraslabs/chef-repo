module DeploymentInfo

  def get_file_source(file_name)
    get_user_id ? "user#{get_user_id}/#{file_name}" : file_name
  end

  def get_user_id
    /-user-(\d+)-topology-/.match(node.name)[1]
  end

  def get_topology_name
    /-topology-(\w+)-node-/.match(node.name)[1]
  end

  def get_node_shortname
    /-node-(\w+)-\d+$/.match(node.name)[1]
  end

  def get_node_rank
    node.name.split("-").last
  end

end