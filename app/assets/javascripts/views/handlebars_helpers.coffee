Handlebars.registerHelper('test-status', (status) ->
  result = switch status
    when 'pass'
      "glyphicon glyphicon-ok-circle passed"
    when 'fail'
      "glyphicon glyphicon-remove-circle failed"
    when 'skip'
      "glyphicon glyphicon glyphicon-ban-circle skip"
    when 'error'
      "glyphicon glyphicon-exclamation-sign error"
    else
      ""
  new Handlebars.SafeString(result)
)

Handlebars.registerHelper('title-case', (value) ->
  Case.title(value)
)

Handlebars.registerHelper('upper-case', (value) ->
  Case.upper(value)
)

Handlebars.registerHelper('pluralize?', (value) ->
  if value != 1
    's'
  else
    ''
)

Handlebars.registerHelper('indent', (value) ->
  firstCharacter = value.charAt(0)
  if ['{','['].indexOf(firstCharacter) >= 0
    vkbeautify.json(value, 4)
  else if firstCharacter == '<'
    vkbeautify.xml(value, 4)
  else
    value
)

Handlebars.registerHelper('checkCharLength', (text, oneChar, twoChar, threeChar, fourChar) ->
  value = "#{text}".length
  return oneChar if(value == 1)
  return twoChar if(value == 2)
  return threeChar if(value == 3)
  return fourChar if(value == 4)
  ''
)

Handlebars.registerHelper('supported-status', (resource, operation) ->
  if resource? && resource.operation? && resource.operation[operation] == true
    return "test-filled"
  else
    return "test-empty"
)

Handlebars.registerHelper('supported-status-text', (resource, operation) ->
  if resource? && resource.operation? && resource.operation[operation] == true
    return "Supported"
  else
    return "Not Supported"
)

Handlebars.registerHelper('percentage', (numerator, denominator) ->
  return "#{Math.round((numerator/denominator) * 100)}%"
)
