class Badge
	
	include Mongoid::Document
	field :id, type: String
	field :name, type: String
	field :suites, type: Array
	field :tests, type: Array
	field :description, type: String
	field :link, type: String
	field :image, type: String

	def create_badges
		# Dummy (Always Pass)
	    dummy_badge = Badge.new({
	      id: "DUMMY",
	      name: "Dummy",
	      suites: [],
	      tests: [],
	      description: "This server exists",
	      link: "www.google.com",
	      image: "logo.png"
	    })
	    #dummy_badge.save
	    # Terminology
	    term_badge = Badge.new({
	      id: "TERM",
	      name: "Terminology",
	      suites: [
	        "connectathonterminologytracktest",
	        "resourcetest_conceptmap",
	        "resourcetest_codesystem",
	        "resourcetest_valueset",
	        "searchtest_codesystem",
	        "searchtest_valueset",
	        "searchtest_conceptmap"
	      ],
	      tests: [],
	      description: "A Terminology server lets healthcare applications make use of codes and value sets without having to become experts in the fine details of code system, value set and concept map resources, and the underlying code systems and terminological principles.",
	      link: "https://www.hl7.org/fhir/terminology-service.html",
	      image: "logo.png"
	    })
	    term_badge.save

	    # Conformance Service
	    # Knowledge Repository
	    # Measure Processor

	    # Security
	    sec_badge = Badge.new({
	      id: "SEC",
	      name: "Security",
	      suites: ["connectathonauditeventandprovenancetracktest"],
	      tests: [],
	      description: "A Security badge is earned when a server complies with OAuth2 protocol.",
	      link: "",
	      image: "logo.png"
	    })
	    sec_badge.save
	    # EHR (Read-Only)
	    ehr_badge = Badge.new({
	      id: "EHR",
	      name: "Electronic Health Record",
	      suites: ["readtest"],
	      tests: [],
	      description: "An Electronic Health Record server provides all the functionality necessary for a user to access a patients medical history including all key administrative clinicla data such as demographics, progress notes, medications, etc.",
	      link: "",
	      image: "logo.png"
	    })
	    ehr_badge.save

	    # Foundation
	    foundation_badge = Badge.new({
	      id: "FOUND",
	      name: "Foundations",
	      suites: [
	        # Framework
	        "resourcetest_bundle",
	        "searchtest_bundle",
	        "resourcetest_basic",
	        "searchtest_basic",
	        "resourcetest_binary",
	        "searchtest_binary",
	          # no domain resource
	        "resourcetest_media",
	        "searchtest_media",
	        
	        # Content Management
	        "resourcetest_documentmanifest",
	        "searchtest_documentmanifest",
	        "resourcetest_documentreference",
	        "searchtest_documentreference",
	        "resourcetest_composition",
	        "searchtest_composition",
	        "resourcetest_list",
	        "searchtest_list",
	        "resourcetest_questionnaire",
	        "searchtest_questionnaire",
	        "resourcetest_questionnaireresponse",
	        "searchtest_questionnaireresponse",
	        
	        # Data Exchange
	        "resourcetest_operationoutcome",
	        "searchtest_operationoutcome",
	          # no parameters
	        "resourcetest_subscription",
	        "searchtest_subscription",
	        "resourcetest_messageheader",
	        "searchtest_messageheader",
	        "resourcetest_messagedefinition",
	        "searchtest_messagedefinition"
	      ],
	      tests: [],
	      description: "The <a href='https://www.hl7.org/fhir/foundation-module.html'>Foundation Module</a> is responsible for the overall infrastructure of the FHIR specification. Every implementer works with content in the foundation module however they use FHIR. The Foundation Module maintains most of the basic documentation for the FHIR specification.",
	      link: "https://www.hl7.org/fhir/foundation-module.html",
	      image: "foundation.png"
	    })
	    foundation_badge.save

	    # Diagnostics
	    diag_badge = Badge.new({
	      id:"DIAGNOSTICS",
	      name:"Diagnostics",
	      suites:[],
	      tests:[],
	      description: "Tests for the diagnostics module",
	      link:"",
	      image: "logo.png"
	    })
	    diag_badge.save

	    # Conformance
	    conformance_badge = Badge.new({
	      id: "CONFORM",
	      name: "Conformance",
	      suites:[],
	      tests:[],
	      description:"Tests for the conformance module",
	      link:"",
	      image: "logo.png"
	    })

	    # Administration
	    admin_badge = Badge.new({
	      id: "ADMIN",
	      name: "Administration",
	      suites: [
	        "connectathonfetchpatientrecordtest",
	        "connectathon_patient_track",
	        "connectathonschedulingtracktest",
	        "resourcetest_patient",
	        "resourcetest_relatedperson",
	        "resourcetest_group",
	        "resourcetest_practitioner",
	        "resourcetest_practitionerrole",
	        "resourcetest_organization",
	        "resourcetest_location",
	        "resourcetest_healthcareservice",
	        "resourcetest_endpoint",
	        "resourcetest_schedule",
	        "resourcetest_slot",
	        "resourcetest_episodeofcare",
	        "resourcetest_encounter",
	        "resourcetest_appointment",
	        "resourcetest_appointmentresponse",
	        "resourcetest_account",
	        "resourcetest_flag",
	        "resourcetest_device",
	        "resourcetest_devicecomponent",
	        "resourcetest_devicemetric",
	        "resourcetest_substance",
	        "searchtest_patient",
	        "searchtest_relatedperson",
	        "searchtest_group",
	        "searchtest_practitioner",
	        "searchtest_practitionerrole",
	        "searchtest_organization",
	        "searchtest_location",
	        "searchtest_healthcareservice",
	        "searchtest_endpoint",
	        "searchtest_schedule",
	        "searchtest_slot",
	        "searchtest_episodeofcare",
	        "searchtest_encounter",
	        "searchtest_appointment",
	        "searchtest_appointmentresponse",
	        "searchtest_account",
	        "searchtest_flag",
	        "searchtest_device",
	        "searchtest_devicecomponent",
	        "searchtest_devicemetric",
	        "searchtest_substance"
	      ],
	      tests:[],
	      description:"The <a href='https://www.hl7.org/fhir/administration-module.html'>administration module</a> covers the base data that is then linked into other modules for clinical content, finance/billing, workflow, etc. Before any clinical data can be recorded, the basic information on the patient must be recorded, and then often the bases of the interaction, such as an encounter.",
	      link:"https://www.hl7.org/fhir/administration-module.html",
	      image: "admin.jpg"
	    })
	    admin_badge.save

	    # Clinical
	    clinical_badge = Badge.new({
	      id: "CLINICAL",
	      name: "Clinical",
	      suites: [],
	      tests: [],
	      description: "Clinical elements and stuff",
	      link: "",
	      image: "logo.png"
	    })
	    clinical_badge.save

	    # Medications
	    med_badge = Badge.new( {
	      id: "MEDS",
	      name: "Medications",
	      suites:[
	        "connectathonpatchtracktest"
	      ],
	      tests:[],
	      description: "Meds and stuff",
	      link:"",
	      image: "logo.png"
	    })
	    med_badge.save

	    # Workflow
	    workflow_badge = Badge.new( {
	      id: "WORK",
	      name: "Workflow",
	      suites:[],
	      tests:[],
	      description: "Workflow of stuff",
	      link:"",
	      image: "logo.png"
	    })
	    workflow_badge.save

	    # Clinical Reasoning
	    reason_badge = Badge.new({
	      id:"REASON",
	      name: "Clinical Reasoning",
	      suites:["connectathon_care_plan_track"],
	      tests:[],
	      description: "Tests related to the clinical reasoning module",
	      link:"",
	      image: "logo.png"
	    })
	    reason_badge.save

	    # Claims
	    claims_badge = Badge.new({
	      id: "CLAIM",
	      name: "Claims",
	      suites: [
	        "connectathonfinancialtracktest",
	        "connectathonattachmenttest",
	        "resourcetest_account",
	        "resourcetest_chargeitem",
	        "resourcetest_claim",
	        "resourcetest_claimresponse",
	        "resourcetest_contract",
	        "resourcetest_coverage",
	        "resourcetest_eligibilityrequest",
	        "resourcetest_eligibilityresponse",
	        "resourcetest_enrollmentrequest",
	        "resourcetest_enrollmentresponse",
	        "resourcetest_explanationofbenefit",
	        "resourcetest_paymentnotice",
	        "resourcetest_paymentreconciliation",
	        "searchtest_account",
	        "searchtest_chargeitem",
	        "searchtest_claim",
	        "searchtest_claimresponse",
	        "searchtest_contract",
	        "searchtest_coverage",
	        "searchtest_eligibilityrequest",
	        "searchtest_eligibilityresponse",
	        "searchtest_enrollmentrequest",
	        "searchtest_enrollmentresponse",
	        "searchtest_explanationofbenefit",
	        "searchtest_paymentnotice",
	        "searchtest_paymentreconciliation"
	      ],
	      tests: [],
	      description: "A claims server provides financial services related to the processing of claims and payments",
	      link: "",
	      image: "logo.png"
	    })
	    claims_badge.save
	end

end

