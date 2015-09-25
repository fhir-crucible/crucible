Handlebars.registerHelper('test-status', (status) -> 
  result = switch status
    when 'pass'
      "glyphicon glyphicon-ok-circle passed"
    when 'fail'
      "glyphicon glyphicon-remove-circle failed"
    when 'skip'
      "glyphicon glyphicon-remove-circle skip"
    else
      ""
  new Handlebars.SafeString(result)
)

