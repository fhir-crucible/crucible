# Module for generating and manipulating compliance JSON and Summary models
module Compliance
  require 'json'
  SECTION = 'children'

  # Aggregates results, builds compliance JSON, and creates new Summary entry,
  # and generates new nightly run if test_run isn't nightly
  def self.build_compliance_json(test_run)
    test_run = generate_nightly_test_run(test_run) unless test_run.nightly
    compliance_file = File.join(Rails.root, 'lib', 'compliance.json')
    compliance = JSON.parse(File.read(compliance_file))
    aggregated_results = aggregate_test_run_results(test_run)
    updated_compliance = update_compliance(compliance, aggregated_results)
    summary = Summary.new(
      server: test_run.server,
      test_run: test_run,
      compliance: updated_compliance,
      generated_at: Time.now
    )
    summary.save
  end

  # Removes the specified array of keys from category and it's children hashes
  def self.remove_compliance_fields(category, keys)
    # find and delete any keys on the top-level category
    overlap = keys & category.keys
    overlap.each do |key|
      category.delete(key)
    end unless overlap.empty?

    # remove any keys from any children
    if category[SECTION]
      category[SECTION].each do |section|
        overlap = keys & section.keys
        overlap.each do |key|
          section.delete(key)
        end unless overlap.empty?
      end
      # keep traversing children to remove all keys
      if category[SECTION][0].try(:[], SECTION)
        category[SECTION].each do |section|
          remove_compliance_fields(section, keys)
        end
      end
    end
    category
  end

  # Aggregate metadata across test results for the given test_run
  def self.aggregate_test_run_results(test_run)
    aggregated_metadata = []
    test_run.test_results.each do |suite_result|
      suite_result.result.each do |test_result|
        test_result['validates'].each do |validate|
          aggregated_metadata << {
            resource: validate[:resource].try(:titleize).try(:downcase),
            result: test_result,
            suite: suite_result
          } if validate[:resource]
          validate[:methods].each do |method|
            aggregated_metadata << {
              method: method,
              result: test_result,
              suite: suite_result
            }
          end if validate[:methods]
          validate[:formats].each do |format|
            aggregated_metadata << {
              format: format,
              result: test_result,
              suite: suite_result
            }
          end if validate[:formats]
        end if test_result['validates']
      end if suite_result.result
    end
    aggregated_metadata
  end

  # Generates a new nightly test run from the given run, and will retain
  # previous test results that were not included in the given run
  def self.generate_nightly_test_run(current_test_run)
    # Find the latest nightly run, clone the given run, and identify new results
    latest_nightly_run = TestRun.where({server_id: current_test_run.server_id, nightly: true}).last
    new_nightly_run = TestRun.new current_test_run.attributes.except('_id')
    current_test_run.test_results.each do |tr|
      new_tr = TestResult.new tr.attributes.except('_id', 'test_run_id')
      new_tr.test_run = new_nightly_run
      new_nightly_run.test_results << new_tr
      new_tr.save
    end
    executed = new_nightly_run.test_results.map(&:test).map(&:id)

    # copy over each result into the cloned run except for the ones we executed
    latest_nightly_run.test_results.each do |suite_result|
      next if executed.include?(suite_result.test.id)
      new_tr = TestResult.new suite_result.attributes.except('_id', 'test_run_id')
      new_tr.test_run = new_nightly_run
      new_nightly_run.test_results << new_tr
      new_tr.save
    end if latest_nightly_run.try(:test_results)

    # mark the clone as nightly and save it
    new_nightly_run.nightly = true
    new_nightly_run.save
    new_nightly_run
  end

  # Updates the given compliance with each metadata in aggregated_metadata
  def self.update_compliance(compliance, aggregated_metadata)
    aggregated_metadata.each do |metadata|
      update_operations(compliance, metadata) if metadata[:method]
      update_resources(compliance, metadata) if metadata[:resource]
      update_formats(compliance, metadata) if metadata[:format]
    end
    update_compliance_totals(compliance)
    compliance
  end

  # DFS to compute SECTION-level summaries of each metadata's status
  def self.update_compliance_totals(category)
    # if we have children
    if category[SECTION]
      # if a child has children
      if category[SECTION][0].try(:[], SECTION)
        # update their totals
        category[SECTION].each do |section|
          update_compliance_totals(section)
        end
      end
      summary = {
        'total' => 0,
        'passed' => 0,
        'failed' => 0,
        'skipped' => 0,
        'errors' => 0,
        'issues' => []
      }
      category[SECTION].each do |section|
        section['total'] ||= 0
        section['passed'] ||= 0
        section['failed'] ||= 0
        section['skipped'] ||= 0
        section['errors'] ||= 0
        summary['total'] += section['total']
        summary['passed'] += section['passed']
        summary['failed'] += section['failed']
        summary['skipped'] += section['skipped']
        summary['errors'] += section['errors']
        summary['issues'].concat section['issues'] if section['issues']
      end
      category.merge! summary
    end
  end

  # Handles updating the given compliance for RESTful operations in metadata
  def self.update_operations(compliance, metadata)
    method = metadata[:method]
    status = metadata[:result]['status']

    # FIXME: Figure out how to handle system-wide operations
    method = method.split('-')[0] if method.include?('-')

    # extract operation leaves from categories
    api = compliance[SECTION]
    operations = api[0][SECTION]
    restful_api = operations[0][SECTION]

    instance = restful_api[0][SECTION]
    type = restful_api[1][SECTION]
    whole = restful_api[2][SECTION]

    extended = operations[1][SECTION]

    # array containing lists of operation leaves
    aggregate_operations = [instance, type, whole, extended]

    # update any operation leaves with a name matching method
    aggregate_operations.each do |list|
      list.each do |operation|
        if operation['name'] == method
          update_metadata(operation, status, metadata, method)
        end
      end
    end
  end

  # Handles updating the given compliance for FHIR Resources in metadata
  def self.update_resources(compliance, metadata)
    resource = metadata[:resource]
    status = metadata[:result]['status']

    # extract resource leaves from categories
    api = compliance[SECTION]
    resources = api[1][SECTION]
    clinical = resources[0][SECTION]
    administrative = resources[1][SECTION]
    infrastructure = resources[2][SECTION]
    financial = resources[3][SECTION]

    general = clinical[0][SECTION]
    data_col_care_plan = clinical[1][SECTION]
    med_imm_nut = clinical[2][SECTION]
    diagnostics = clinical[3][SECTION]

    attribution = administrative[0][SECTION]
    entities = administrative[1][SECTION]
    workflow = administrative[2][SECTION]
    scheduling = administrative[3][SECTION]

    isupport = infrastructure[0][SECTION]
    idocument = infrastructure[1][SECTION]
    exchange = infrastructure[2][SECTION]
    conformance = infrastructure[3][SECTION]

    fsupport = financial[0][SECTION]
    billing = financial[1][SECTION]
    payment = financial[2][SECTION]
    other = financial[3][SECTION]

    # array containing lists of resource leaves
    aggregate_resources = [
      general, data_col_care_plan, med_imm_nut,
      diagnostics, attribution, entities, workflow, scheduling, isupport,
      idocument, exchange, conformance, fsupport, billing, payment, other]

    # update any resource leaves with a name matching resource, lowercased
    aggregate_resources.each do |list|
      list.each do |res|
        if res['name'].downcase == resource.downcase
          update_metadata(res, status, metadata, resource.downcase)
        end
      end
    end
  end

  # Handles updating the given compliance for FHIR Formats in metadata
  def self.update_formats(compliance, metadata)
    format = metadata[:format]
    status = metadata[:result]['status']

    # extract format leaves from categories
    api = compliance[SECTION]
    formats = api[2][SECTION]

    # update any format leaves with a name matching method
    formats.each do |fhir_format|
      if fhir_format['name'] == format
        update_metadata(fhir_format, status, metadata, format)
      end
    end
  end

  # Handles updating the given metadata for the given status and any issues
  def self.update_metadata(metadata, status, test_info=nil, tag=nil)
    metadata['total'] ||= 0
    metadata['total'] += 1
    case status
    when 'pass'
      metadata['passed'] ||= 0
      metadata['passed'] += 1
    when 'fail'
      metadata['failed'] ||= 0
      metadata['failed'] += 1
    when 'skip'
      metadata['skipped'] ||= 0
      metadata['skipped'] += 1
    when 'error'
      metadata['errors'] ||= 0
      metadata['errors'] += 1
    end
    if ['fail','error'].include?(status) && test_info && tag
      test_result_id = test_info[:result]['id']
      msg = test_info[:result]['message'] || 'Missing message description for test failure.'
      msg = msg.first if test_info[:result]['message'].class == Array

      issue = {
        suite_id: test_info[:suite].test_id,
        test_id: test_result_id,
        test_result_id: test_info[:suite].id,
        test_method: test_info[:result][:test_method],
        msg: msg,
        tag: tag
      }

      metadata['issues'] ||= []
      metadata['issues'] << issue
    end
  end

end
