module Graph

  class Node
    def initialize(name, context)
      @name = name
      @context = context
      update_data
    end

    def name
      @name
    end

    def [](key)
      @data[key]
    end

    def wait_for_attr(key, options={})
      timeout = options[:timeout] || 300

      for i in 1 .. timeout
        update_data
        return true if self[key]

        sleep 1
      end

      false
    end

    def private_network?
      if self["node_info"] && self["node_info"]["private_network"] == "true"
        return true
      else
        return false
      end
    end

    def cluster_name
      name.split("_node_").last.sub(/_\d+$/, "")
    end

    def first_node_of_cluster?
      name.end_with?("_1")
    end

    private

    def update_data
      node_name = name
      @data = @context.instance_eval{ data_bag_item(node_name, node_name) }
    end
  end


  def get_connected_nodes(type, options={})
    source_node = options[:source_node] || node.name
    nodes_names = data_bag_item(source_node, source_node)[type] || Array.new
    nodes_names.map do |node_name|
      Graph::Node.new(node_name, self)
    end
  end

  def respond_to?(method_name)
    method_name.to_s =~ /^get_(.+)$/ || super
  end

  def method_missing(method_name, *args, &block)
    if method_name.to_s =~ /^get_(.+)$/
      connection_type = $1
      get_connected_nodes(connection_type)
    else
      super
    end
  end

end