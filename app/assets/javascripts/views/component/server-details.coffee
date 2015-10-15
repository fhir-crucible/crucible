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
    @element.find('.server-name-panel').tooltip()
    @element.find('.server-url-panel').tooltip()

  toggleEditDialogue: =>
    @element.find('.editToggle').toggleClass('hide')

  editServerName: (newName) =>
    newName = @element.find('#edit-server-name-dialogue').val()
    newURL = @element.find('#edit-server-url-dialogue').val()
    $.ajax({
      type: 'PUT',
      url: "/servers/#{@serverId}",
      data: {server: {name: newName, url: newURL}},
      success: ((data) =>
        @element.find('.server-name-label').html(newName) 
        @element.find('.server-name-panel').attr('title', newName).tooltip('fixTitle')
        @element.find('.server-url-label').html(newURL) 
        @element.find('.server-url-panel').attr('title', newURL).tooltip('fixTitle')

        @toggleEditDialogue()
      )
      fail: ((data) =>
        @toggleEditDialogue()
        @element.find('.edit-panel').show()
      )
    });
