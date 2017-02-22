Session::getCustomDataTypes = ->
     @getDefaults().server.custom_data_types or {}

class CustomDataTypeGVK extends CustomDataType

     # put custom css to head
     CUI.ready =>
        style = DOM.element("style")
        style.innerHTML = ".gvkPopover { min-width:600px !important; min-height: 400px !important; } .gvkInput .cui-button-visual, .gvkSelect .cui-button-visual { width: 100%; } .gvkSelect > div { width: 100%; }"
        document.head.appendChild(style)

     #######################################################################
     # return name of plugin
     getCustomDataTypeName: ->
          "custom:base.custom-data-type-gvk.gvk"


     #######################################################################
     # return name (l10n) of plugin
     getCustomDataTypeNameLocalized: ->
          $$("custom.data.type.gvk.name")

     #######################################################################
     # check if field is empty
     # needed for editor-table-view
     isEmpty: (data, top_level_data, opts) ->
         if data[@name()]?.conceptName
             false
         else
             true

     #######################################################################
     # handle editorinput
     renderEditorInput: (data, top_level_data, opts) ->
          # console.error @, data, top_level_data, opts, @name(), @fullName()
          if not data[@name()]
               cdata = {
                        conceptName : ''
                        conceptURI : ''
                    }
               data[@name()] = cdata
          else
               cdata = data[@name()]

          @__renderEditorInputPopover(data, cdata)


      #######################################################################
      # buttons, which open and close popover
      __renderEditorInputPopover: (data, cdata) ->
        @__layout = new HorizontalLayout
          left:
            content:
                new Buttonbar(
                  buttons: [
                      new Button
                          text: ""
                          icon: 'edit'
                          group: "groupA"

                          onClick: (ev, btn) =>
                            @showEditPopover(btn, cdata, data)

                      new Button
                          text: ""
                          icon: 'trash'
                          group: "groupA"
                          onClick: (ev, btn) =>
                            # delete data
                            cdata = {
                                  conceptName : ''
                                  conceptURI : ''
                            }
                            data[@name()] = cdata
                            # trigger form change
                            Events.trigger
                              node: @__layout
                              type: "editor-changed"
                            @__updateGVKResult(cdata)
                  ]
                )
          center: {}
          right: {}
        @__updateGVKResult(cdata)
        @__layout


     #######################################################################
     # update result in Masterform
     __updateGVKResult: (cdata) ->
          btn = @__renderButtonByData(cdata)
          @__layout.replace(btn, "right")


     #######################################################################
     # handle suggestions-menu
     __updateSuggestionsMenu: (cdata, cdata_form, suggest_Menu, gvk_xhr) ->
          that = @

          delayMillisseconds = 200

          setTimeout ( ->

              gvk_searchterm = cdata_form.getFieldsByName("gvkSearchBar")[0].getValue()
              gvk_countSuggestions = cdata_form.getFieldsByName("gvkSelectCountOfSuggestions")[0].getValue()

              if gvk_searchterm.length == 0
                  return

              # run autocomplete-search via xhr
              if gvk_xhr != undefined
                  # abort eventually running request
                  gvk_xhr.abort()
              # start new request
              # build searchurl
              url = location.protocol + '//ws.gbv.de/suggest/csl/?query=pica.all=' + gvk_searchterm + '&citationstyle=ieee&language=de&count=' + gvk_countSuggestions
              gvk_xhr = new (CUI.XHR)(url: url)
              gvk_xhr.start().done((data, status, statusText) ->

                  CUI.debug 'OK', gvk_xhr.getXHR(), gvk_xhr.getResponseHeaders()

                  # create new menu with suggestions
                  menu_items = []
                  # the actual Featureclass
                  actualFclass = ''
                  for suggestion, key in data[1]
                       do(key) ->
                            if (actualFclass == '' || actualFclass != data[2][key])
                                 actualFclass = data[2][key]
                                 item =
                                      divider: true
                                 menu_items.push item
                                 item =
                                      label: actualFclass
                                 menu_items.push item
                                 item =
                                      divider: true
                                 menu_items.push item
                            item =
                                 text: suggestion
                                 value: data[3][key]

                            menu_items.push item

                  # set new items to menu
                  itemList =
                       onClick: (ev2, btn) ->
                            # lock in save data
                            cdata.conceptURI = btn.getOpt("value")
                            cdata.conceptName = btn.getText()
                            # lock in form
                            cdata_form.getFieldsByName("conceptName")[0].storeValue(cdata.conceptName).displayValue()
                            # nach eadb5-Update durch "setText" ersetzen und "__checkbox" rausnehmen
                            cdata_form.getFieldsByName("conceptURI")[0].__checkbox.setText(cdata.conceptURI)
                            cdata_form.getFieldsByName("conceptURI")[0].show()

                            # clear searchbar
                            cdata_form.getFieldsByName("gvkSearchBar")[0].setValue('')
                       items: menu_items

                  # if no hits set "empty" message to menu
                  if itemList.items.length == 0
                       itemList =
                            items: [
                                 text: "kein Treffer"
                                 value: undefined
                            ]

                  suggest_Menu.setItemList(itemList)

                  suggest_Menu.show()

              )
              .fail (data, status, statusText) ->
                  CUI.debug 'FAIL', gvk_xhr.getXHR(), gvk_xhr.getResponseHeaders()
          ), delayMillisseconds


     #######################################################################
     # reset form
     __resetGVKForm: (cdata, cdata_form) ->
          # clear variables
          cdata.conceptName = ''
          cdata.conceptURI = ''

          # reset type-select
          cdata_form.getFieldsByName("gvkSelectFeatureClasses")[0].setValue("DifferentiatedPerson")

          # reset count of suggestions
          cdata_form.getFieldsByName("gvkSelectCountOfSuggestions")[0].setValue(20)

          # reset searchbar
          cdata_form.getFieldsByName("gvkSearchBar")[0].setValue("")

          # reset result name
          cdata_form.getFieldsByName("conceptName")[0].storeValue("").displayValue()

          # reset and hide result-uri-button
          cdata_form.getFieldsByName("conceptURI")[0].__checkbox.setText("")
          cdata_form.getFieldsByName("conceptURI")[0].hide()


     #######################################################################
     # if something in form is in/valid, set this status to masterform
     __setEditorFieldStatus: (cdata, element) ->
          switch @getDataStatus(cdata)
               when "invalid"
                    element.addClass("cui-input-invalid")
               else
                    element.removeClass("cui-input-invalid")

          Events.trigger
               node: element
               type: "editor-changed"

          @

     #######################################################################
     # show popover and fill it with the form-elements
     showEditPopover: (btn, cdata, data) ->

          # init xhr
          gvk_xhr = undefined

          # set default value for count of suggestions
          cdata.gvkSelectCountOfSuggestions = 20
          cdata_form = new Form
               data: cdata
               fields: @__getEditorFields(cdata)
               onDataChanged: =>
                    @__updateGVKResult(cdata)
                    @__setEditorFieldStatus(cdata, @__layout)
                    @__updateSuggestionsMenu(cdata, cdata_form, suggest_Menu, gvk_xhr)
          .start()

          # init suggestmenu
          suggest_Menu = new Menu
              element : cdata_form.getFieldsByName("gvkSearchBar")[0]
              use_element_width_as_min_width: true

          @popover = new Popover
               element: btn
               placement: "wn"
               class: "gvkPopover"
               pane:
                    # titel of popovers
                    header_left: new LocaLabel(loca_key: "custom.data.type.gvk.edit.modal.title")
                    # "save"-button
                    footer_right: new Button
                        text: "Übernehmen"
                        onClick: =>
                             # put data to savedata
                             data[@name()] = {
                                  conceptName : cdata.conceptName
                                  conceptURI : cdata.conceptURI
                             }
                             # close popup
                             @popover.destroy()
                    # "reset"-button
                    footer_left: new Button
                        text: "Zurücksetzen"
                        onClick: =>
                             @__resetGVKForm(cdata, cdata_form)
                             @__updateGVKResult(cdata)
                    content: cdata_form
          .show()


     #######################################################################
     # create form
     __getEditorFields: (cdata) ->
          fields = [
               {
                    type: Select
                    class: "gvkSelect"
                    undo_and_changed_support: false
                    form:
                        label: $$('custom.data.type.gvk.modal.form.text.count')
                    options: [
                         (
                             value: 10
                             text: '10 Vorschläge'
                         )
                         (
                             value: 20
                             text: '20 Vorschläge'
                         )
                         (
                             value: 50
                             text: '50 Vorschläge'
                         )
                         (
                             value: 100
                             text: '100 Vorschläge'
                         )
                    ]
                    name: 'gvkSelectCountOfSuggestions'
               }
               {
                    type: Input
                    class: "gvkInput"
                    undo_and_changed_support: false
                    form:
                        label: $$("custom.data.type.gvk.modal.form.text.searchbar")
                    placeholder: $$("custom.data.type.gvk.modal.form.text.searchbar.placeholder")
                    name: "gvkSearchBar"
               }
               {
                    form:
                         label: "Gewählter Eintrag"
                    type: Output
                    name: "conceptName"
                    data: {conceptName: cdata.conceptName}
               }
               {
                    form:
                         label: "Verknüpfter Katalogeintrag"
                    type: FormButton
                    name: "conceptURI"
                    icon: new Icon(class: "fa-lightbulb-o")
                    text: cdata.conceptURI
                    onClick: (evt,button) =>
                         window.open cdata.conceptURI, "_blank"
                    onRender : (_this) =>
                         if cdata.conceptURI == ''
                              _this.hide()
               }]

          fields

     #######################################################################
     # renders details-output of record
     renderDetailOutput: (data, top_level_data, opts) ->
          @__renderButtonByData(data[@name()])


     #######################################################################
     # checks the form and returns status
     getDataStatus: (cdata) ->
            if (cdata)
                if cdata.conceptURI and cdata.conceptName
                        # check url for valididy
                        uriCheck = CUI.parseLocation(cdata.conceptURI)

                        # /^(https?|ftp):\/\/(((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:)*@)?(((\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]))|((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?)(:\d*)?)(\/((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)+(\/(([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)*)*)?)?(\?((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|[\uE000-\uF8FF]|\/|\?)*)?(\#((([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(%[\da-f]{2})|[!\$&'\(\)\*\+,;=]|:|@)|\/|\?)*)?$/i.test(value);

                        # uri-check patch!?!? returns always a result

                        nameCheck = if cdata.conceptName then cdata.conceptName.trim() else undefined

                        if uriCheck and nameCheck
                                console.debug "getDataStatus: OK "
                                return "ok"

                        if cdata.conceptURI.trim() == '' and cdata.conceptName.trim() == ''
                                console.debug "getDataStatus: empty"
                                return "empty"

                        console.debug "getDataStatus returns invalid"
                        return "invalid"
                else
                        cdata = {
                                    conceptName : ''
                                    conceptURI : ''
                                }
                        console.debug "getDataStatus: empty"
                        return "empty"
            else
                    cdata = {
                                conceptName : ''
                                conceptURI : ''
                            }
                    console.debug "getDataStatus: empty"
                    return "empty"



     #######################################################################
     # renders the "result" in original form (outside popover)
     __renderButtonByData: (cdata) ->
          # when status is empty or invalid --> message
          switch @getDataStatus(cdata)
               when "empty"
                    return new EmptyLabel(text: $$("custom.data.type.gvk.edit.no_gvk")).DOM
               when "invalid"
                    return new EmptyLabel(text: $$("custom.data.type.gvk.edit.no_valid_gvk")).DOM

          # if status is ok
          conceptURI = CUI.parseLocation(cdata.conceptURI).url

          # output Button with Name of literature-entry
          new ButtonHref
               appearance: "link"
               href: cdata.conceptURI
               target: "_blank"
               text: cdata.conceptName
          .DOM


     #######################################################################
     # is called, when record is being saved by user
     getSaveData: (data, save_data, opts) ->
          cdata = data[@name()] or data._template?[@name()]
          switch @getDataStatus(cdata)
               when "invalid"
                    throw InvalidSaveDataException
               when "empty"
                    save_data[@name()] = null
               when "ok"
                    save_data[@name()] =
                         conceptName: cdata.conceptName.trim()
                         conceptURI: cdata.conceptURI.trim()

     renderCustomDataOptionsInDatamodel: (custom_settings) ->
          new Label(text: "Keine Optionen möglich")


CustomDataType.register(CustomDataTypeGVK)
