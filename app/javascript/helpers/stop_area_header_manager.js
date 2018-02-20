import React, { Component } from 'react'

export default class StopAreaHeaderManager {
  constructor(ids_list, stopPointsList, features) {
    this.ids_list = ids_list
    this.stopPointsList = stopPointsList
    this.features = features
  }

  hasFeature(key) {
    return this.features[key]
  }

  stopPointHeader(object_id) {
    let index = this.ids_list.indexOf(object_id)
    let sp = this.stopPointsList[index]
    let showHeadline = this.showHeader(object_id)
    let title = sp.city_name ? sp.city_name + ' (' + sp.zip_code +')' : ""
    if(sp.waiting_time > 0){
      title += " | " + sp.waiting_time_text
    }
    return (
      <div
        className={(showHeadline) ? 'headlined' : ''}
        data-headline={showHeadline}
        title={title}
      >
        <span>
          <span>
            {sp.name}
            {sp.time_zone_formatted_offset && <span className="small">
              &nbsp;({sp.time_zone_formatted_offset})
            </span>}
            {sp.area_kind == 'non_commercial' && <span className="fa fa-question-circle" title={sp.area_type_i18n}>
            </span>}
          </span>
        </span>
      </div>
    )
  }

  showHeader(object_id) {
    let showHeadline = false
    let headline = ""
    let attribute_to_check = this.hasFeature('long_distance_routes') ? "country_code" : "city_name"
    let index = this.ids_list.indexOf(object_id)
    let sp = this.stopPointsList[index]
    let previousBreakpoint = this.stopPointsList[index - 1]
    if(sp == undefined){
      console.log("STOP_POINT NOT FOUND: " + object_id)
      console.log("AVAILABLE IDS:" + this.ids_list)
      return
    }
    if(index == 0 || (sp[attribute_to_check] != previousBreakpoint[attribute_to_check])){
      showHeadline = true
      headline = this.hasFeature('long_distance_routes') ? sp.country_name : sp.city_name
    }
    return showHeadline ? headline : ""
  }
}
