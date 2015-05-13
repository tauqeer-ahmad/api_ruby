class Generator
  def self.clean
    `rm -f lib/tsheets/{models,repos}/*.rb`
  end

  def self.run! config
    new.run! config
  end

  def run! config
    generate_models! config['objects']
    generate_repos! config['endpoints']
  end

  def write_dynamic! path, contents
    FileUtils.touch "lib/tsheets/#{path}"
    File.write "lib/tsheets/#{path}", contents
  end

  def generate_models! models_config
    models_config.each do |name, config|
      generate_model! name, config
    end
  end

  def generate_model! name, config
    write_dynamic! "models/#{name}.rb", code_for_model(name, config)
  end

  def code_for_model name, config
    template = <<-EOF
      class <%= class_name %> < TSheets::Model
        <% config.each do |field_name, field_config| %>
          field :<%= field_name %>, :<%= field_config %>
        <% end %>
      end
    EOF
    class_name = to_class_name name
    ERB.new(template).result binding
  end

  def generate_repos! endpoints_config
    endpoints_config.each do |name, config|
      generate_repo! name, config
    end
  end

  def generate_repo! name, config
    write_dynamic! "repos/#{name}.rb", code_for_repo(name, config)
  end

  def code_for_repo name, config
    template = <<-EOF
      class <%= class_name %> < TSheets::Repo
        url <%= config['url'] %>
        model <%= model_class %>
        actions <%= actions.map { |a| ":#{a}" }.join(', ')  %>
        <% config['filters'].each do |field_name, field_config| %>
          <% if field_config[/\[\]/] %>
            filter :<%= field_name %>, [ :#{field_config.gsub(/\[\]/, '')} ]
          <% else %>
            filter :<%= field_name %>, :<%= field_config %>
          <% end %>
        <% end %>
      end
    EOF
    class_name = to_class_name name
    model_class = to_class_name config['model']
    actions = config['actions']
    ERB.new(template).result binding
  end

  def to_class_name name
    name.split('_').map { |s| s.capitalize }.join
  end
end
