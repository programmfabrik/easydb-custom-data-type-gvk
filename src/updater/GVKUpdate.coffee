class GVKUpdate

  __start_update: ({server_config, plugin_config}) ->
      ez5.respondSuccess({
        state: {
            "start_update": new Date().toUTCString()
        }
      })

  __updateData: ({objects, plugin_config}) ->
    that = @
    objectsMap = {}
    GVKIds = []
    for object in objects
      if not (object.identifier and object.data)
        continue
      gvkURI = object.data.conceptURI
      if !gvkURI
        console.error "GVK-URI " + gvkURI + " is empty!?"
        continue
      gvkID = gvkURI.split('/')
      gvkID = gvkID.pop()
      gvkID = gvkID.replace('gvk:ppn:','')

      if CUI.util.isEmpty(gvkID)
        continue
      if not objectsMap[gvkID]
        objectsMap[gvkID] = [] # It is possible to  have more than one object with the same ID in different objects.
      objectsMap[gvkID].push(object)
      GVKIds.push(gvkID)

    if GVKIds.length == 0
      return ez5.respondSuccess({payload: []})

    # unique gvk-ids
    GVKIds = GVKIds.filter((x, i, a) => a.indexOf(x) == i)

    objectsToUpdate = []

    # update the uri's one after the other
    chunkWorkPromise = CUI.chunkWork.call(@,
      items: GVKIds
      chunk_size: 1
      call: (items) =>
        GVKId = items[0]
        # get updates from csl-service
        xurl = 'https://ws.gbv.de/suggest/csl2/?query=pica.ppn=' + GVKId + '&citationstyle=ieee&language=de&count=1'
        deferred = new CUI.Deferred()
        extendedInfo_xhr = new (CUI.XHR)(url: xurl)
        extendedInfo_xhr.start()
        .done((data, status, statusText) ->
          # validation-test on 1-hit
          if data[1].length == 1
            gvkURI = data[3][0]
            gvkID = gvkURI.split('/')
            gvkID = gvkID.pop()
            gvkID = gvkID.replace('gvk:ppn:','')
            resultsGVKID = gvkID

            # then build new cdata and aggregate in objectsMap (see below)
            updatedGVKcdata = {}
            updatedGVKcdata.conceptURI = gvkURI
            #updatedGNDcdata.conceptName = Date.now() + '_' + data['preferredName']
            updatedGVKcdata.conceptName = data[1][0]

            updatedGVKcdata._standard =
              text: updatedGVKcdata.conceptName

            updatedGVKcdata._fulltext =
              string: updatedGVKcdata.conceptName + ' ' + gvkURI + ' ' + gvkID
            if !objectsMap[resultsGVKID]
              console.error "GVK nicht in objectsMap: " + resultsGVKID
              console.error "da hat sich die PPN von " + GVKId + " zu " + resultsGVKID + " geändert"
            for objectsMapEntry in objectsMap[GVKId]
              if not that.__hasChanges(objectsMapEntry.data, updatedGVKcdata)
                continue
              objectsMapEntry.data = updatedGVKcdata # Update the object that has changes.
              objectsToUpdate.push(objectsMapEntry)
          deferred.resolve()
        ).fail( =>
          deferred.reject()
        )
        return deferred.promise()
    )

    chunkWorkPromise.done(=>
      ez5.respondSuccess({payload: objectsToUpdate})
    ).fail(=>
      ez5.respondError("custom.data.type.gvk.update.error.generic", {error: "Error connecting to GVK-API"})
    )

  __hasChanges: (objectOne, objectTwo) ->
    for key in ["conceptName", "conceptURI", "_standard", "_fulltext"]
      if not CUI.util.isEqual(objectOne[key], objectTwo[key])
        return true
    return false

  main: (data) ->
    if not data
      ez5.respondError("custom.data.type.gvk.update.error.payload-missing")
      return

    for key in ["action", "server_config", "plugin_config"]
      if (!data[key])
        ez5.respondError("custom.data.type.gvk.update.error.payload-key-missing", {key: key})
        return

    if (data.action == "start_update")
      @__start_update(data)
      return

    else if (data.action == "update")
      if (!data.objects)
        ez5.respondError("custom.data.type.gvk.update.error.objects-missing")
        return

      if (!(data.objects instanceof Array))
        ez5.respondError("custom.data.type.gvk.update.error.objects-not-array")
        return

      if (!data.state)
        ez5.respondError("custom.data.type.gvk.update.error.state-missing")
        return

      if (!data.batch_info)
        ez5.respondError("custom.data.type.gvk.update.error.batch_info-missing")
        return

      @__updateData(data)
      return
    else
      ez5.respondError("custom.data.type.gvk.update.error.invalid-action", {action: data.action})

module.exports = new GVKUpdate()
