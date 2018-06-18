class CustomDataTypeGVK extends CustomDataTypeWithCommons

     #######################################################################
     # return name of plugin
     getCustomDataTypeName: ->
          "custom:base.custom-data-type-gvk.gvk"


     #######################################################################
     # return name (l10n) of plugin
     getCustomDataTypeNameLocalized: ->
          $$("custom.data.type.gvk.name")


     #######################################################################
     # handle suggestions-menu
     __updateSuggestionsMenu: (cdata, cdata_form, suggest_Menu, searchsuggest_xhr) ->
          that = @

          delayMillisseconds = 200

          setTimeout ( ->

              gvk_searchterm = cdata_form.getFieldsByName("searchbarInput")[0].getValue()
              gvk_countSuggestions = cdata_form.getFieldsByName("countOfSuggestions")[0].getValue()

              if gvk_searchterm.length == 0
                  return

              # run autocomplete-search via xhr
              if searchsuggest_xhr.xhr != undefined
                  # abort eventually running request
                  searchsuggest_xhr.xhr.abort()
              # start new request
              # build searchurl
              url = location.protocol + '//ws.gbv.de/suggest/csl/?query=pica.all=' + gvk_searchterm + '&citationstyle=ieee&language=de&count=' + gvk_countSuggestions
              searchsuggest_xhr.xhr = new (CUI.XHR)(url: url)
              searchsuggest_xhr.xhr.start().done((data, status, statusText) ->

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
                                 #center: new CUI.Label(text: suggestion, multiline: true)
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
                            cdata_form.getFieldsByName("conceptURI")[0].setText(cdata.conceptURI)
                            cdata_form.getFieldsByName("conceptURI")[0].show()

                            # clear searchbar
                            cdata_form.getFieldsByName("searchbarInput")[0].setValue('')
                       items: menu_items

                  # if no hits set "empty" message to menu
                  if itemList.items.length == 0
                       itemList =
                            items: [
                                 text: $$('custom.data.type.gvk.modal.form.text.no_hit')
                                 value: undefined
                            ]
                  
                  suggest_Menu.setItemList(itemList)

                  suggest_Menu.show()

              )
          ), delayMillisseconds



     #######################################################################
     # create form
     __getEditorFields: (cdata) ->
          fields = [
               {
                    type: CUI.Select
                    class: "commonPlugin_Select"
                    undo_and_changed_support: false
                    form:
                        label: $$('custom.data.type.gvk.modal.form.text.count')
                    options: [
                         (
                             value: 10
                             text: '10 ' + $$('custom.data.type.gvk.modal.form.text.count_short')
                         )
                         (
                             value: 20
                             text: '20 ' + $$('custom.data.type.gvk.modal.form.text.count_short')
                         )
                         (
                             value: 50
                             text: '50 ' + $$('custom.data.type.gvk.modal.form.text.count_short')
                         )
                         (
                             value: 100
                             text: '100 ' + $$('custom.data.type.gvk.modal.form.text.count_short')
                         )
                    ]
                    name: 'countOfSuggestions'
               }
               {
                    type: CUI.Input
                    class: "commonPlugin_Input"
                    undo_and_changed_support: false
                    form:
                        label: $$("custom.data.type.gvk.modal.form.text.searchbar")
                    placeholder: $$("custom.data.type.gvk.modal.form.text.searchbar.placeholder")
                    name: "searchbarInput"
               }
               {
                    form:
                         label: $$('custom.data.type.gvk.modal.form.text.result.label')
                    type: CUI.Output
                    name: "conceptName"
                    data: {conceptName: cdata.conceptName}
               }
               {
                    form:
                         label: $$('custom.data.type.gvk.modal.form.text.uri.label')
                    type: CUI.FormButton
                    name: "conceptURI"
                    icon: new CUI.Icon(class: "fa-lightbulb-o")
                    text: cdata.conceptURI
                    onClick: (evt,button) =>
                         window.open cdata.conceptURI, "_blank"
                    onRender : (_this) =>
                         if cdata.conceptURI == ''
                              _this.hide()
               }]

          fields


     #######################################################################
     # renders the "result" in original form (outside popover)
     __renderButtonByData: (cdata) ->

        # when status is empty or invalid --> message

        switch @getDataStatus(cdata)
             when "empty"
                  return new CUI.EmptyLabel(text: $$("custom.data.type.gvk.edit.no_gvk")).DOM
             when "invalid"
                  return new CUI.EmptyLabel(text: $$("custom.data.type.gvk.edit.no_valid_gvk")).DOM

        # if status is ok
        conceptURI = CUI.parseLocation(cdata.conceptURI).url

        # output Button with Name of literature-entry
        new CUI.ButtonHref
             appearance: "link"
             href: cdata.conceptURI
             target: "_blank"
             text: cdata.conceptName
        .DOM

     #######################################################################
     # zeige die gewählten Optionen im Datenmodell unter dem Button an
     getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
        tags = []

        #tags.push " - Ohne Optionen - "

        tags

CustomDataType.register(CustomDataTypeGVK)
