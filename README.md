# Crucible Server [![Build Status](https://travis-ci.org/fhir-crucible/crucible.svg?branch=master)](https://travis-ci.org/fhir-crucible/crucible)

A simple Rails app for evaluating FHIR.

## Details ##
  - Ruby 2.5+
  - Rails 4.1+
  - Bootstrap
  - MongoDB 2.6
  - Bundler
  - Node
  - Bower

## Getting Started ##

### Docker Installation

- Install [Docker](https://www.docker.com/)
- Checkout Crucible: `git clone https://github.com/fhir-crucible/crucible.git`
- Build the server: `docker-compose build`
- Start the server: `docker-compose up`
- Navigate to `http://localhost:3000`

### OSX Installation ###

#### Dependencies
- Install [Homebrew](http://brew.sh/)
- Install [RVM](https://rvm.io/)
- Install Ruby 2.5+ via `rvm install 2.5`
- Install [MongoDB](https://www.mongodb.org/) via `brew install mongodb`
- Install [Bundler](http://bundler.io/) via `gem install bundler`
- Install [Node](https://nodejs.org/) via `brew install node`
- Install [Bower](http://bower.io/) via `npm install -g bower`

#### Server
- Checkout Crucible: `git clone https://github.com/fhir-crucible/crucible.git`
- Install Ruby dependencies with Bundler: `bundle install`
- Install Javascript dependencies with Bower: `bower install`
- Start MongoDB: `mongod`
- Launch the Rails server: `bundle exec rails server`
- Launch the Job Runner: `RAILS_ENV=development bin/delayed_job start`

#### Testing Crucible Code
##### Ruby Tests
- Execute: `bundle exec rake test`

##### Front end tests
- Install phantomjs: `brew install phantomjs`
- Install istanbul: `npm install -g istanbul`
- Execute: `bundle exec rake teaspoon`

### Production Linux Installation ###

- [Ubuntu Install Instructions](https://github.com/fhir-crucible/crucible/wiki/Installation-Instructions-%28Ubuntu-14.04%29)
- [CentOS Install Instructions](https://github.com/fhir-crucible/crucible/wiki/Installation-Instructions-%28CentOS-7.1.1503%29)

## Authentication With Scopes

In order to authenticate a server with Crucible, the server must be capable of supporting the [SMART On FHIR authorization workflows](http://docs.smarthealthit.org/authorization/).

### Conformance

The server to be tested must declare their compliance with the SMART authorization specification by including security and extension elements in the conformance.

#### Abbreviated Example Conformance (in JSON)
```javascript
{
"resourceType": "Conformance",
"rest": [{
  "security": {
    "service": [
      {
        "coding": [
          {
            "system": "http://hl7.org/fhir/restful-security-service",
            "code": "SMART-on-FHIR"
          }
        ],
        "text": "OAuth2 using SMART-on-FHIR profile (see http://docs.smarthealthit.org)"
      }
    ],
    "extension": [{
      "url": "http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris",
      "extension": [{
        "url": "token",
        "valueUri": "https://my-server.org/token"
      },{
        "url": "authorize",
        "valueUri": "https://my-server.org/authorize"
      }]
    }],
```

Once this code has been included in the conformance, visiting the server's page in Crucible should display a red "padlock" icon in the upper left hand corner.
If the padlock doesn't show up, you may have to refresh the conformance by going to the "Conformance" tab and clicking on the "Refresh" button, then refresh the page.

##### The refresh button:
![The refresh button on the "Conformance" tab](https://raw.githubusercontent.com/fhir-crucible/mock-ups/doc_images/docs/refresh_button.png "Located on the top right of the tab")

### Registration
In order to use the FHIR server, you must first register a client with the FHIR server. The process for doing this varies depending on the server being accessed.

### Authorization process
Clicking on the padlock icon brings up the "Authorize" popup. Here, you can add authorization details about the server being tested.

##### Input fields on the authorization popup
![Authorization popup](https://raw.githubusercontent.com/fhir-crucible/mock-ups/doc_images/docs/authorize_popup.png "Fields in the authorization popup")

#### Authorize Popup Details
* __Client ID:__ used to define the client accessing the server. Provided by the server.
* __Client Secret:__ If the client is registered using the SMART confidential profile, this will be provided by the server. If the client is using the SMART public profile, this will be left blank.
* __Patient ID:__ if the server does not have the ability to pick a patient at authorization time, such as in the EHR launch sequence, you can add a patient ID which will be passed to the tests
* __Launch Parameter:__ Used only in the EHR launch sequence, this parameter is issued by the EHR and given to the SMART on FHIR app.
* __Scope:__ SMART on FHIR's authorization scheme uses OAuth scopes to communicate (and negotiate) access requirements. For more information on scopes, see http://docs.smarthealthit.org/authorization/scopes-and-launch-context/ . In general, for Crucible, `Patient/*.read` should be selected, to provide access to the requested patient and all resources associated with it. If using the EHR launch sequence, or otherwise not picking a patient through the UI, you should select adequate scopes for the resources being requested. `fhir_complete` or `user/*.read`, if available, are good choices. For Argonaut tests, Crucible only requires read permissions, as nothing is written to the FHIR server.

##### Some of the scopes in the authorization popup
![A selection of scopes](https://raw.githubusercontent.com/fhir-crucible/mock-ups/doc_images/docs/scopes.png "The first four scopes")

Once the requisite details have been entered into the popup, scroll to the bottom and click "Authorize App". This should take you to the FHIR server's authorization page, where you can complete the process on the server side.

##### The authorize button, located at the bottom of the authorization popup
![The "authorize" button](https://raw.githubusercontent.com/fhir-crucible/mock-ups/doc_images/docs/authorize_button.png)

Once authorization has been completed successfully, you will see a green notice that says "Server successfully authorized", and the lock icon will turn green, indicating a valid access token has been issued. At this point, you can run any tests requiring authorization.

##### A correctly-authorized server
![The server details showing a green padlock](https://raw.githubusercontent.com/fhir-crucible/mock-ups/doc_images/docs/authorized_server.png)

### Renewal

If the access token expires, as defined by the date passed by the server when the token was issued, Crucible will try to use a refresh token (if present) to request a new access token.

If no refresh token is available, or the refresh attempt fails, the lock icon will revert to red, showing that the server is no longer authorized. You will have to complete the authorization process again.

# License

Copyright 2015-2018 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
