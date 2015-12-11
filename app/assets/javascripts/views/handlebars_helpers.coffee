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

Handlebars.registerHelper('indent', (value) ->
  firstCharacter = value.charAt(0)
  if ['{','['].indexOf(firstCharacter) >= 0
    vkbeautify.json(value, 4)
  else if firstCharacter == '<'
    vkbeautify.xml(value, 4)
  else
    value
)

Handlebars.registerHelper('supported-status', (resource, operation) ->
  if resource? && resource.operation[operation] == true
    return "test-filled"
  else
    return "test-empty"
)
