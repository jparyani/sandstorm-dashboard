Future = Npm.require('fibers/future')

isNumber = (n) ->
  return !isNaN(parseFloat(n)) && isFinite(n)

# Meteor._wrapAsync fails for some reason
@wrappedGet = (binding, url, creds) ->
  fut = new Future()
  binding.get url, creds.accessToken, creds.accessTokenSecret, (err, data) ->
    if err
      fut.throw err
    else
      fut.return data

  return fut.wait()

fetch = (collection, start, end, resample, sum, options) ->
  res = []
  nextTimestamp = 0
  options = options || {}

  if (not options.sort)
    options.sort = {timestamp: 1}

  if resample
  # TODO: filter
    raw = collection.find({}, options).forEach (doc) ->
      time = doc.timestamp.getTime()

      if time > nextTimestamp
        if nextTimestamp == 0
          nextTimestamp = time
        else
          while nextTimestamp < time
            nextTimestamp += resample

        res.push doc

  else
    res = collection.find({}, options).fetch()

  if res.length
    newData = {}
    keys = Object.keys(res[0])
    for key in keys
      newData[key] = []

    for row in res
      for key in keys
        newData[key].push row[key]

    if collection == LogData
      newData['timestamp'] = _.map newData['timestamp'], (val) ->
        return new Date(val)

    if sum
      for key in keys
        first = newData[key][0]
        if +first == first or key == 'ga:sessions' or key == 'ga:hits'
          total = 0
          newData[key] = _.map newData[key], (val) ->
            total += +val
            return total

      newData["_count"] = _.range(1, res.length + 1)
      if collection == LogData
        total = 0
        newData["count_daily"] = _.map newData['type'], (val) ->
          if val == 'daily'
            total += 1
          return total
        total = 0
        newData["count_install"] = _.map newData['type'], (val) ->
          if val == 'install'
            total += 1
          return total
        total = 0
        newData["count_startup"] = _.map newData['type'], (val) ->
          if val == 'startup'
            total += 1
          return total
        total = 0
        newData["count_manual"] = _.map newData['type'], (val) ->
          if val == 'manual'
            total += 1
          return total
        total = 0
        newData["count_retry"] = _.map newData['type'], (val) ->
          if val == 'retry'
            total += 1
          return total

    res = newData

  return res

fetchLatest = (collection) ->
  return collection.findOne({}, {sort: {$natural: -1 }, limit: 1})

Meteor.methods
  updateDashboard: (data) ->
    unless isAdmin(Meteor.userId())
      throw new Meteor.Error(403, "Unauthorized", "Must be admin")

    data.userId = Meteor.userId()
    Dashboards.upsert({userId: Meteor.userId()}, data)

  setupTwitter: (credentialToken, credentialSecret) ->
    unless isAdmin(Meteor.userId())
      throw new Meteor.Error(403, "Unauthorized", "Must be admin")

    data = OauthRetrieveCredential(credentialToken, credentialSecret)
    options = data.serviceData
    Meteor.users.update {_id: Meteor.userId()}, {'$set': {'profile.isTwitterSetup': true, 'services.twitter': options}}
    startTwitterTimer(options)

  fetchLatestTwitter: ->
    unless isAdmin(Meteor.userId())
      throw new Meteor.Error(403, "Unauthorized", "Must be admin")

    return fetchLatest(TwitterData)

  fetchLatestMailchimp: ->
    unless isAdmin(Meteor.userId())
      throw new Meteor.Error(403, "Unauthorized", "Must be admin")

    return fetchLatest(MailchimpData)

  fetchLatestGoogle: ->
    unless isAdmin(Meteor.userId())
      throw new Meteor.Error(403, "Unauthorized", "Must be admin")

    return fetchLatest(GoogleData)

  fetchLatestGithub: ->
    unless isAdmin(Meteor.userId())
      throw new Meteor.Error(403, "Unauthorized", "Must be admin")

    return fetchLatest(GithubData)

  fetchLatestLog: ->
    unless isAdmin(Meteor.userId())
      throw new Meteor.Error(403, "Unauthorized", "Must be admin")

    return fetchLatest(LogData)

  fetchTwitter: (start, end, resample) ->
    unless isAdmin(Meteor.userId())
      throw new Meteor.Error(403, "Unauthorized", "Must be admin")

    return fetch(TwitterData, start, end, resample, false, {fields: {timestamp: 1, followers_count: 1, statuses_count: 1}})

  fetchMailchimp: (start, end, resample) ->
    unless isAdmin(Meteor.userId())
      throw new Meteor.Error(403, "Unauthorized", "Must be admin")

    return fetch(MailchimpData, start, end, resample)

  fetchGoogle: (start, end, resample) ->
    unless isAdmin(Meteor.userId())
      throw new Meteor.Error(403, "Unauthorized", "Must be admin")

    return fetch(GoogleData, start, end, resample, true)

  fetchGithub: (start, end, resample) ->
    unless isAdmin(Meteor.userId())
      throw new Meteor.Error(403, "Unauthorized", "Must be admin")

    return fetch(GithubData, start, end, resample)

  fetchSandstorm: (start, end, resample) ->
    unless isAdmin(Meteor.userId())
      throw new Meteor.Error(403, "Unauthorized", "Must be admin")

    return fetch(SandstormData, start, end, resample)

  fetchLog: (start, end, resample) ->
    unless isAdmin(Meteor.userId())
      throw new Meteor.Error(403, "Unauthorized", "Must be admin")

    return fetch(LogData, start, end, resample, true)
