class SmartsController < ApplicationController
  before_filter :set_oauth

  # GET /smart
  def index
  end

  # GET /smart/app
  def app
    @app_params = params
    @app_session = session
    @invalid_launch = false
    @invalid_launch_state = false
    @other_launch_error = false
    if params['error']
      if params['error_uri']
        redirect_to params['error_uri']
      else
        @invalid_launch = true
      end
    elsif params['state'] != session[:state]
      @invalid_launch_state = true
    elsif params['state'].nil? || params['code'].nil? || session[:client_id].nil? || session[:token_url].nil? || session[:fhir_url].nil?
      @other_launch_error = true
    else
      session[:start_time] = Time.now
      # Get the OAuth2 token
      puts "App Params: #{params}"

      oauth2_params = {
        'grant_type' => 'authorization_code',
        'code' => params['code'],
        'redirect_uri' => Rails.application.config.smart_redirect_url,
        'client_id' => session[:client_id]
      }
      puts "Token Params: #{oauth2_params}"
      token_response = RestClient.post(session[:token_url], oauth2_params)
      token_response = JSON.parse(token_response.body)
      @token_response = token_response
      puts "Token Response: #{token_response}"
      token = token_response['access_token']
      session[:token] = token
      fhir_url = session[:fhir_url]
      patient_id = token_response['patient']
      session[:patient_id] = patient_id
      scopes = token_response['scope']
      if scopes.nil?
        scopes = get_scopes(fhir_url)
      end
      session[:scopes] = scopes
    end

    render stream: true
  end

  # GET /smart/app/show
  def show
    token = session[:token]
    fhir_url = session[:fhir_url]
    scopes = session[:scopes]
    patient_id = session[:patient_id]

    # Configure the FHIR Client
    client = FHIR::Client.new(fhir_url)
    version = client.detect_version
    client.set_bearer_token(token)
    client.default_json

    # Check FHIR client
    unless client.is_a?(FHIR::Client)
      raise "Invalid client. Expected FHIR client."
    end

    # Check FHIR version
    if client.detect_version == :dstu2
      version = client.detect_version
      klass_header = "FHIR::DSTU2::"
      conformance_klass = FHIR::DSTU2::Conformance
      supporting_resources = [
        FHIR::DSTU2::AllergyIntolerance, FHIR::DSTU2::CarePlan, FHIR::DSTU2::Condition,
        FHIR::DSTU2::DiagnosticOrder, FHIR::DSTU2::DiagnosticReport, FHIR::DSTU2::Encounter,
        FHIR::DSTU2::FamilyMemberHistory, FHIR::DSTU2::Goal, FHIR::DSTU2::Immunization,
        FHIR::DSTU2::List, FHIR::DSTU2::Procedure, FHIR::DSTU2::MedicationAdministration,
        FHIR::DSTU2::MedicationDispense, FHIR::DSTU2::MedicationOrder,
        FHIR::DSTU2::MedicationStatement, FHIR::DSTU2::Observation, FHIR::DSTU2::RelatedPerson
      ]
      # Vital Signs includes these codes as defined in http://loinc.org
      vital_signs = {
        '9279-1' => 'Respiratory rate',
        '8867-4' => 'Heart rate',
        '2710-2' => 'Oxygen saturation in Capillary blood by Oximetry',
        '55284-4' => 'Blood pressure systolic and diastolic',
        '8480-6' => 'Systolic blood pressure',
        '8462-4' => 'Diastolic blood pressure',
        '8310-5' => 'Body temperature',
        '8302-2' => 'Body height',
        '8306-3' => 'Body height --lying',
        '8287-5' => 'Head Occipital-frontal circumference by Tape measure',
        '3141-9' => 'Body weight Measured',
        '39156-5' => 'Body mass index (BMI) [Ratio]',
        '3140-1' => 'Body surface area Derived from formula',
        '59408-5' => 'Oxygen saturation in Arterial blood by Pulse oximetry',
        '8478-0' => 'Mean blood pressure'
      }
    elsif client.detect_version == :stu3
      version = client.detect_version
      klass_header = "FHIR::"
      conformance_klass = FHIR::CapabilityStatement
      supporting_resources = [
        FHIR::AllergyIntolerance, FHIR::CarePlan, FHIR::CareTeam, FHIR::Condition, FHIR::Device,
        FHIR::DiagnosticReport, FHIR::Goal, FHIR::Immunization, FHIR::MedicationRequest,
        FHIR::MedicationStatement, FHIR::Observation, FHIR::Procedure, FHIR::RelatedPerson, FHIR::Specimen
      ]
      # Vital Signs includes these codes as defined in http://hl7.org/fhir/STU3/observation-vitalsigns.html
      vital_signs = {
        '85353-1' => 'Vital signs, weight, height, head circumference, oxygen saturation and BMI panel',
        '9279-1' => 'Respiratory Rate',
        '8867-4' => 'Heart rate',
        '59408-5' => 'Oxygen saturation in Arterial blood by Pulse oximetry',
        '8310-5' => 'Body temperature',
        '8302-2' => 'Body height',
        '8306-3' => 'Body height --lying',
        '8287-5' => 'Head Occipital-frontal circumference by Tape measure',
        '29463-7' => 'Body weight',
        '39156-5' => 'Body mass index (BMI) [Ratio]',
        '85354-9' => 'Blood pressure systolic and diastolic',
        '8480-6' => 'Systolic blood pressure',
        '8462-4' => 'Diastolic blood pressure'
      }
    else
      raise "Invalid FHIR client. Expected STU3 or DSTU2 version."
    end

    # Parse accessible resources from scopes
    if scopes.scan(/patient\/(.*?)\.[read|\*]/).include?(["*"])
      accessible_resources = supporting_resources.dup
    else
      accessible_resources = scopes.scan(/patient\/(.*?)\.[read|\*]/).map {|w| Object.const_get("#{klass_header}#{w.first}")}
    end

    # Parse readable resources from conformance
    if client.conformance_statement.is_a?(conformance_klass)
      statement_details = client.conformance_statement.to_hash
      readable_resource_names = statement_details['rest'][0]['resource'].select {|r|
        r['interaction'].include?({"code"=>"read"})
      }.map {|n| n['type']}
    else
      raise "Invalid conformance statement. Expected #{conformance_klass.name}."
    end

    report = {}
    @pass = 0
    @fail = 0
    @skip = 0
    @not_found = 0

    # Get the patient demographics
    patient = client.read(Object.const_get("#{klass_header}Patient"), patient_id).resource
    report[:patient] = result('Patient Successfully Retrieved',patient.is_a?(Object.const_get("#{klass_header}Patient")),patient.id)
    patient_details = patient.to_hash

    # DAF/US-Core CCDS
    patient_name = "#{patient_details['name'][0]['given'][0]} #{patient_details['name'][0]['family'][0]}" rescue nil
    report[:patient_name] = result('Patient Name',patient_details['name'],patient_name)

    report[:patient_gender] = result('Patient Gender',patient_details['gender'],patient_details['gender'])

    report[:patient_dob] = result('Patient Date of Birth',patient_details['birthDate'],patient_details['birthDate'])

    # US Extensions
    extensions = {
      'Race' => 'http://hl7.org/fhir/StructureDefinition/us-core-race',
      'Ethnicity' => 'http://hl7.org/fhir/StructureDefinition/us-core-ethnicity',
      'Religion' => 'http://hl7.org/fhir/StructureDefinition/us-core-religion',
      'Mother\'s Maiden Name' => 'http://hl7.org/fhir/StructureDefinition/patient-mothersMaidenName',
      'Birth Place' => 'http://hl7.org/fhir/StructureDefinition/birthPlace'
    }
    required_extensions = ['Race','Ethnicity']
    extensions.each do |name,url|
      detail = nil
      check = :not_found
      if patient_details['extension']
        detail = patient_details['extension'].find{|e| e['url']==url }
        check = !detail.nil? if required_extensions.include?(name)
      elsif required_extensions.include?(name)
        check = false
      end
      report['patient_'.concat(name).delete('\'').tr(' ','_').downcase.to_sym] = result("Patient #{name}", check, (detail['valueCodeableConcept']['coding'][0]['display'] rescue nil))
    end

    report[:patient_preferred_language] = result('Patient Preferred Language',(patient_details['communication'] && patient_details['communication'].find{|c|c['language'] && c['preferred']}),patient_details['communication'])

    # Get the patient's smoking status
    # {"coding":[{"system":"http://loinc.org","code":"72166-2"}]}
    search_reply = client.search(Object.const_get("#{klass_header}Observation"), search: { parameters: { 'patient' => patient_id, 'code' => 'http://loinc.org|72166-2'}})
    search_reply_length = search_reply.try(:resource).try(:entry).try(:length)
    unless search_reply_length.nil?
      if accessible_resources.include?(Object.const_get("#{klass_header}Observation")) # If resource is in scopes
        if search_reply_length == 0
          if readable_resource_names.include?("Observation")
            report[:smoking_status] = result("Smoking Status",:not_found)
          else
            report[:smoking_status] = result("Smoking Status",:skip,"Read capability for resource not in conformance statement.")
          end
        elsif search_reply_length > 0
          report[:smoking_status] = result("Smoking Status",true,(search_reply.resource.entry.first.to_fhir_json rescue nil))
        else
          if readable_resource_names.include?("Observation") # If comformance claims read capability for resource
            report[:smoking_status] = result("Smoking Status",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
          else
            report[:smoking_status] = result("Smoking Status",:skip,"Read capability for resource not in conformance statement.")
          end
        end
      else # If resource is not in scopes
        if search_reply_length > 0
          report[:smoking_status] = result("Smoking Status",false,"Resource provided without required scopes.")
        else
          report[:smoking_status] = result("Smoking Status",:skip,"Access not granted through scopes.")
        end
      end
    else
      if readable_resource_names.include?("Observation") # If comformance claims read capability for resource
        report[:smoking_status] = result("Smoking Status",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
      else
        report[:smoking_status] = result("Smoking Status",:skip,"Read capability for resource not in conformance statement.")
      end
    end

    # Get the patient's allergies
    # There should be at least one. No known allergies should have a negated entry.
    # Include these codes as defined in http://snomed.info/sct
    #   Code	     Display
    #   160244002	No Known Allergies
    #   429625007	No Known Food Allergies
    #   409137002	No Known Drug Allergies
    #   428607008	No Known Environmental Allergy
    search_reply = client.search(Object.const_get("#{klass_header}AllergyIntolerance"), search: { parameters: { 'patient' => patient_id } })
    search_reply_length = search_reply.try(:resource).try(:entry).try(:length)
    unless search_reply_length.nil?
      if accessible_resources.include?(Object.const_get("#{klass_header}AllergyIntolerance")) # If resource is in scopes
        if search_reply_length == 0
          if readable_resource_names.include?("AllergyIntolerance")
            report[:allergyintolerances] = result("AllergyIntolerances",false,"No Known Allergies.")
          else
            report[:allergyintolerances] = result("AllergyIntolerances",:skip,"Read capability for resource not in conformance statement.")
          end
        elsif search_reply_length > 0
          report[:allergyintolerances] = result("AllergyIntolerances",true,"Found #{search_reply_length} AllergyIntolerance.")
        else
          if readable_resource_names.include?("AllergyIntolerance") # If comformance claims read capability for resource
            report[:allergyintolerances] = result("AllergyIntolerances",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
          else
            report[:allergyintolerances] = result("AllergyIntolerances",:skip,"Read capability for resource not in conformance statement.")
          end
        end
      else # If resource is not in scopes
        if search_reply_length > 0
          report[:allergyintolerances] = result("AllergyIntolerances",false,"Resource provided without required scopes.")
        else
          report[:allergyintolerances] = result("AllergyIntolerances",:skip,"Access not granted through scopes.")
        end
      end
    else
      if readable_resource_names.include?("AllergyIntolerance") # If comformance claims read capability for resource
        report[:allergyintolerances] = result("AllergyIntolerances",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
      else
        report[:allergyintolerances] = result("AllergyIntolerances",:skip,"Read capability for resource not in conformance statement.")
      end
    end

    vital_signs.each do |code,display|
      search_reply = client.search(Object.const_get("#{klass_header}Observation"), search: { parameters: { 'patient' => patient_id, 'code' => "http://loinc.org|#{code}" } })
      search_reply_length = search_reply.try(:resource).try(:entry).try(:length)
      unless search_reply_length.nil?
        if accessible_resources.include?(Object.const_get("#{klass_header}Observation")) # If resource is in scopes
          if search_reply_length == 0
            if readable_resource_names.include?("Observation")
              report['vital_sign_'.concat(code).tr('-','_').to_sym] = result("Vital Sign: #{display}",:not_found)
            else
              report['vital_sign_'.concat(code).tr('-','_').to_sym] = result("Vital Sign: #{display}",:skip,"Read capability for resource not in conformance statement.")
            end
          elsif search_reply_length > 0
            report['vital_sign_'.concat(code).tr('-','_').to_sym] = result("Vital Sign: #{display}",true,"Found #{search_reply_length} Vital Sign: #{display}.")
          else
            if readable_resource_names.include?("Observation") # If comformance claims read capability for resource
              report['vital_sign_'.concat(code).tr('-','_').to_sym] = result("Vital Sign: #{display}",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
            else
              report['vital_sign_'.concat(code).tr('-','_').to_sym] = result("Vital Sign: #{display}",:skip,"Read capability for resource not in conformance statement.")
            end
          end
        else # If resource is not in scopes
          if search_reply_length > 0
            report['vital_sign_'.concat(code).tr('-','_').to_sym] = result("Vital Sign: #{display}",false,"Resource provided without required scopes.")
          else
            report['vital_sign_'.concat(code).tr('-','_').to_sym] = result("Vital Sign: #{display}",:skip,"Access not granted through scopes.")
          end
        end
      else
        if readable_resource_names.include?("Observation") # If comformance claims read capability for resource
          report['vital_sign_'.concat(code).tr('-','_').to_sym] = result("Vital Sign: #{display}",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
        else
          report['vital_sign_'.concat(code).tr('-','_').to_sym] = result("Vital Sign: #{display}",:skip,"Read capability for resource not in conformance statement.")
        end
      end
    end

    supporting_resources.each do |klass|
      unless [Object.const_get("#{klass_header}AllergyIntolerance"), Object.const_get("#{klass_header}Observation")].include?(klass) # Do not test for AllergyIntolerance or Observation
        puts "Getting #{klass.name.demodulize}s"
        search_reply = client.search(klass, search: { parameters: { 'patient' => patient_id } })
        search_reply_length = search_reply.try(:resource).try(:entry).try(:length)
        unless search_reply_length.nil?
          if accessible_resources.include?(klass) # If resource is in scopes
            if search_reply_length == 0
              if readable_resource_names.include?(klass.name.demodulize)
                report[klass.name.demodulize.downcase.to_sym] = result("#{klass.name.demodulize}s",:not_found)
              else
                report[klass.name.demodulize.downcase.to_sym] = result("#{klass.name.demodulize}s",:skip,"Read capability for resource not in conformance statement.")
              end
            elsif search_reply_length > 0
              report[klass.name.demodulize.downcase.to_sym] = result("#{klass.name.demodulize}s",true,"Found #{search_reply_length} #{klass.name.demodulize}.")
            else
              if readable_resource_names.include?(klass.name.demodulize) # If comformance claims read capability for resource
                report[klass.name.demodulize.downcase.to_sym] = result("#{klass.name.demodulize}s",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
              else
                report[klass.name.demodulize.downcase.to_sym] = result("#{klass.name.demodulize}s",:skip,"Read capability for resource not in conformance statement.")
              end
            end
          else # If resource is not in scopes
            if search_reply_length > 0
              report[klass.name.demodulize.downcase.to_sym] = result("#{klass.name.demodulize}s",false,"Resource provided without required scopes.")
            else
              report[klass.name.demodulize.downcase.to_sym] = result("#{klass.name.demodulize}s",:skip,"Access not granted through scopes.")
            end
          end
        else
          if readable_resource_names.include?(klass.name.demodulize) # If comformance claims read capability for resource
            report[klass.name.demodulize.downcase.to_sym] = result("#{klass.name.demodulize}s",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
          else
            report[klass.name.demodulize.downcase.to_sym] = result("#{klass.name.demodulize}s",:skip,"Read capability for resource not in conformance statement.")
          end
        end
      end
    end

    total = @pass + @not_found + @skip + @fail
    report[:passed] = { success: true, status: "PASSED", description: "#{((@pass.to_f / total.to_f)*100.0).round}% (#{@pass} of #{total})", detail: "Tests passed." }
    report[:unfound] = { success: :not_found, status: "NOT FOUND", description: "#{((@not_found.to_f / total.to_f)*100.0).round}% (#{@not_found} of #{total})", detail: "Tests not found." }
    report[:skipped] = { success: :skip, status: "SKIPPED", description: "#{((@skip.to_f / total.to_f)*100.0).round}% (#{@skip} of #{total})", detail: "Tests skipped." }
    report[:failed] = { success: false, status: "FAILED", description: "#{((@fail.to_f / total.to_f)*100.0).round}% (#{@fail} of #{total})", detail: "Tests failed." }

    session[:end_time] = Time.now
    time_diff = TimeDifference.between(session[:start_time],session[:end_time]).humanize
    run = SmartRun.new
    run.report = report
    run.time_diff = time_diff
    run.smart_client = SmartClient.find_by(client_id: session[:client_id])
    run.save
    render json: { report: report, time_diff: time_diff }
  end

  # GET /smart/app/launch
  def launch
    @launch_params = params
    if params && params['iss'] && params['launch']
      @valid_launch_params = true
      client_id = get_client_id(params['iss'])
      auth_info = get_auth_info(params['iss'])
      session[:client_id] = client_id
      session[:fhir_url] = params['iss']
      session[:authorize_url] = auth_info[:authorize_url]
      session[:token_url] = auth_info[:token_url]
      @fhir_url = params['iss']
      puts "Launch Client ID: #{client_id}\nLaunch Auth Info: #{auth_info}\nLaunch Redirect: #{Rails.application.config.smart_redirect_url}"
      session[:state] = SecureRandom.uuid
      oauth2_params = {
        'response_type' => 'code',
        'client_id' => client_id,
        'redirect_uri' => Rails.application.config.smart_redirect_url,
        'scope' => get_scopes(params['iss']),
        'launch' => params['launch'],
        'state' => session[:state],
        'aud' => params['iss']
      }
      oauth2_auth_query = "#{session[:authorize_url]}?"
      oauth2_params.each do |key,value|
        oauth2_auth_query += "#{key}=#{CGI.escape(value)}&"
      end
      puts "Launch Authz Query: #{oauth2_auth_query[0..-2]}"
      redirect_to oauth2_auth_query[0..-2]
    else
      @valid_launch_params = false
    end
  end

  # GET /smart/app/cfg
  def cfg
  end

  # POST /smart/app/cfg
  def update_cfg
    if params['delete']
      puts "Deleting configuration: #{params['delete']}"
      delete_client(params['delete'])
    else
      puts "Saving configuration: #{params}"
      add_client(params['Server'],params['Client ID'],params['Scopes'])
    end
    puts "Configuration saved."
    @config_data = get_config
    redirect_to "/smart/cfg"
  end

  # Helper function to output result of test
  def result(description,success,detail='Not available')
    detail = 'Not available' if detail.nil?
    if success==:not_found
      @not_found += 1
      status = 'NOT FOUND'
    elsif success==:skip
      @skip += 1
      status = 'SKIPPED'
    elsif success
      @pass += 1
      status = 'PASS'
    else
      @fail += 1
      status = 'FAIL'
    end
    { success: success, status: status, description: description, detail: detail }
  end

  # Given a URL, choose a client_id to use
  def get_client_id(url)
    return nil unless url
    SmartClient.all.each do |client|
      return client.client_id if url.include?(client.name)
    end
    nil
  end

  # Given a URL, choose the OAuth2 scopes to request
  def get_scopes(url)
    return nil unless url
    SmartClient.all.each do |client|
      return client.scopes if url.include?(client.name)
    end
    nil
  end

  # Extract the Authorization and Token URLs
  # from the FHIR Conformance
  def get_auth_info(issuer)
    return {} unless issuer
    client = FHIR::Client.new(issuer)
    client.default_json
    client.get_oauth2_metadata_from_conformance
  end

  def get_config
    rows = []
    SmartClient.all.each do |client|
      rows << { client: client.name, client_id: client.client_id, scopes: client.scopes }
    end
    rows
  end

  # Add a smart_client to the database
  def add_client(name,client_id,scopes)
    client = SmartClient.new
    client.name = name
    client.client_id = client_id
    client.scopes = scopes
    # Destroy smart_client if it shares new smart_client name
    SmartClient.all.each do |other|
      unless other == client
        other.destroy if other.name == client.name
      end
    end
    client.save
  end

  # Delete a smart_client from the database
  def delete_client(name)
    client = SmartClient.find_by(name: name)
    client.destroy if client
  end

  private
  def set_oauth
    @config_data = get_config
  end
end
