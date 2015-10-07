module Aggregate
  require 'json'

  def self.update(server, test_run)
    server.aggregate_run ||= AggregateRun.new
    aggregate_run = server.aggregate_run
    aggregate_run.results ||= []
    
    result_map = {}
    test_run.test_results.each do |test_result|
      test_result.result.each do |result|
        id = result['id']
        if result_map[id]
          puts "\tduplicate id: #{id}!!!!!!!" 
        else
          result['test_result_id'] = test_result.id
          result['test_id'] = test_result.test_id
          result_map[id] = result.except('code')
        end
      end
    end

    latest_results = aggregate_run.results.map {|result| (result_map.delete(result['id']) || result.except('code')) }
    latest_results.concat(result_map.values)
    aggregate_run.results = latest_results
    aggregate_run.date = Time.now
    aggregate_run.save!
    server.save!
  end

  def self.get_compliance(server)
    compliance_file = File.join(Rails.root, 'lib', 'compliance.json')
    compliance = JSON.parse(File.read(compliance_file))

    node_map = {}
    build_compliance_node_map(compliance, node_map)
    server.aggregate_run.results.each do |result|
      result['validates'].each do |validation|
        if validation[:resource]
          update_node(node_map, validation[:resource].titleize.downcase, result)
        end
        if validation[:methods]
          validation[:methods].each do |method|
            update_node(node_map, method, result)
          end
        end
        if validation[:formats]
          validation[:formats].each do |format|
            update_node(node_map, format, result)
          end
        end
        if validation[:extensions]
          validation[:extensions].each do |extension|
            update_node(node_map, extension, result)
          end
        end
        if validation[:profiles]
          validation[:profiles].each do |profile|
            update_node(node_map, profile, result)
          end
        end

      end if result['validates']
    end

    rollup(compliance)

    compliance
  end

  def self.rollup(node)
    if node['children']
      node['children'].each do |child|
        rollup(child)
      end
      ['passed', 'failed', 'errors', 'skipped'].each do |key|
        node["#{key}Ids"].concat(node['children'].map {|n| n["#{key}Ids"]}.flatten.uniq)
        node["#{key}Ids"].uniq!
        node[key] = node["#{key}Ids"].count
        node['total'] += node[key]
      end
    end
  end

  def self.update_node(node_map, key, result)
    status_map = {'pass'=>'passed', 'fail'=>'failed','error'=>'errors', 'skip'=>'skipped'}
    node = node_map[key]
    if (node)
      node[status_map[result['status']]] += 1
      node["#{status_map[result['status']]}Ids"] << result['id']
      node['total'] += 1
    else
      puts "\t KEY NOT FOUND: #{key}"
    end
  end

  def self.build_compliance_node_map(node, map)
    node_defaults = {
      'passed'=>0,'failed'=>0, 'errors'=>0, 'skipped'=>0, 'total'=>0,
      'passedIds'=>[],'failedIds'=>[], 'errorsIds'=>[], 'skippedIds'=>[]
    }
    raise "duplicate node: #{node['name']}" if map[node['name']]
    map[node['name']] = node.merge!(node_defaults)
    if node['children']
      node['children'].each do |child|
        build_compliance_node_map(child, map)
      end
    end
  end

end
