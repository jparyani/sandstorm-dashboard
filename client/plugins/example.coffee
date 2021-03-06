myDatasourcePlugin = (settings, updateCallback) ->
  # This is some function where I'll get my data from somewhere
  getData = ->
    newData = hello: Math.random()
    # Get my data from somewhere and populate newData with it... Probably a JSON API or something.

    # ...
    updateCallback newData
    return
  createRefreshTimer = (interval) ->
    clearInterval refreshTimer  if refreshTimer
    refreshTimer = setInterval(->
      getData()
      return
    , interval)
    return
  self = this
  currentSettings = settings
  refreshTimer = undefined
  self.onSettingsChanged = (newSettings) ->
    clearInterval refreshTimer
    currentSettings = newSettings
    createRefreshTimer currentSettings.refresh_time
    return

  self.updateNow = ->
    getData()
    return

  self.onDispose = ->
    clearInterval refreshTimer
    refreshTimer = `undefined`
    return

  Meteor.setTimeout(->
    current_time = currentSettings.past_time
    while current_time > 0
      self.updateNow()
      current_time -= currentSettings.refresh_time
  , 3000)

  createRefreshTimer currentSettings.refresh_time
  return

@loadExamplePlugin = ->
  freeboard.loadDatasourcePlugin
    type_name: "my_datasource_plugin"
    display_name: "Datasource Plugin Example"
    description: "Some sort of description <strong>with optional html!</strong>"
    settings: [
      {
        name: "past_time"
        display_name: "Historical Time To Display"
        type: "text"
        description: "In milliseconds"
        default_value: 500000
      }
      {
        name: "refresh_time"
        display_name: "Refresh Time"
        type: "text"
        description: "In milliseconds"
        default_value: 5000
      }
    ]
    newInstance: (settings, newInstanceCallback, updateCallback) ->
      newInstanceCallback new myDatasourcePlugin(settings, updateCallback)
      return

