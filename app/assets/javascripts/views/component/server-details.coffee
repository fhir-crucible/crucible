$(window).on('load', ->
  new Crucible.ServerDetails()
)

class Crucible.ServerDetails

  constructor: ->
    @element = $('.server-details')
    return unless @element.length
    @serverId = @element.data('server-id')
    @registerHandlers()

  registerHandlers: =>
    @element.find('.edit-server-name-icon').click(@toggleEditDialogue)
    @element.find('.submit-server-name').click(@editServerName)

  toggleEditDialogue: =>
    @element.find('.edit-panel').toggleClass('hide')
    @element.find('.server-name-panel').toggleClass('hide')
    @element.find('.server-url-panel').toggleClass('hide')

  editServerName: (newName) =>
    newName = @element.find('#edit-server-name-dialogue').val()
    newURL = @element.find('#edit-server-url-dialogue').val()
    $.ajax({
      type: 'PUT',
      url: "/api/servers/#{@serverId}",
      data: {server: {name: newName, url: newURL}},
      success: ((data) =>
        @element.find('.server-name-label').html(newName) 
        @element.find('.server-url-label').html(newURL) 
        @toggleEditDialogue()
      )
      fail: ((data) =>
        @element.find('.edit-panel').show()
        @element.find('.server-name-panel').hide()
        @element.find('.server-url-panel').hide()
      )
    });