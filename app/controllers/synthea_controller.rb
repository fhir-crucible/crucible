class SyntheaController < ApplicationController

  # GET /testdata
  def index
    @testdata = []
    @resources_created = Hash.new(0)
  end

  # POST /testdata
  def load_data
    @testdata = []
    @resources_created = Hash.new(0)

    begin
      server_url = params['server_url']
      format_type = params['format_type']
      quantity = params['quantity'].to_i
      redirected = false

      client = FHIR::Client.new(server_url)
      client.default_format = FHIR::Formats::ResourceFormat::RESOURCE_JSON if format_type=='JSON'
      client.default_format_bundle = FHIR::Formats::FeedFormat::FEED_JSON if format_type=='JSON'

      world = Synthea::World::Sequential.new
      world.population_count = 0
     
      count = 0

      (1..quantity).each do |i|
        # generate a patient with synthea
        record = world.build_person(nil, rand(0..100), nil, nil, nil)
        record = Synthea::Output::Exporter.filter_for_export(record)

        # add a record of the demographics to @testdata
        @testdata << [ record[:name_last], record[:name_first], record[:age], record[:gender], record[:race], 'FAILED' ]
        # convert to FHIR
        bundle = Synthea::Output::FhirRecord.convert_to_fhir(record)
        # record some counts of Resource types
        bundle.entry.each do |entry|
          type = entry.resource.resourceType
          @resources_created[type] += 1
        end
        # upload the patient bundle
        reply = fhir_upload(client,bundle)
        if !reply.nil?
          if [200,201].include?(reply.code)
            count += 1 
            id = patient_id_from_reply(reply)
            @testdata.last[-1] = "#{server_url}/#{id}" if !id.nil?
          elsif (reply.code >= 300 && reply.code < 400)
            @error = "HTTP 3XX Redirects were not followed." if !redirected
            redirected = true
          else
            @error = "HTTP #{reply.code} was returned." if !redirected
          end
        end
      end

      @notice = "Successfully loaded #{count} of #{quantity} record(s)." if count > 0
    rescue Exception => e 
      @message = "Failed to load records."
      @error = "Unexpected error: #{e.message}"
      logger.error @error
      logger.error e.backtrace.join("\n    ")
    end
    render action: 'index'
  end

  def fhir_upload(client,bundle)
    client.begin_transaction
    bundle.entry.each do |entry|
      #defined our own 'add to transaction' function to preserve our entry information
      add_entry_transaction(entry,client)
    end
    f = File.open('test_bundle.json','w:UTF-8')
    f.write(client.transaction_bundle.to_json)
    f.close
    begin
      # return one bundle uploaded
      reply = client.end_transaction
    rescue Exception => e
      @error = "FHIR Transaction error: #{e.message}"
      logger.error @error
      logger.error e.backtrace.join("\n    ")
      # return no bundles uploaded
      nil 
    end
  end
      
  def add_entry_transaction(entry, client)
    entry.request = FHIR::Bundle::Entry::Request.new
    entry.request.local_method = 'POST'
    options = Hash.new
    options[:resource] = entry.resource.class
    entry.request.url = client.resource_url(options)
    entry.request.url = request.url[1..-1] if request.url.starts_with?('/')
    client.transaction_bundle.entry << entry
    entry
  end

  def patient_id_from_reply(reply)
    begin
      reply.resource = FHIR.from_contents(reply.body) if reply.resource.nil?
    rescue Exception => e
      # ignore
    end
    begin
      url = reply.resource.entry.find{|x|x.response.location =~ /Patient/}.response.location
      # id = FHIR::ResourceAddress.pull_out_id(FHIR::Patient,url)
    rescue Exception => e
      logger.error 'Unable to extract patient id from reply'
      logger.error e.message
      logger.error e.backtrace.join("\n    ")
      nil
    end
  end

end
