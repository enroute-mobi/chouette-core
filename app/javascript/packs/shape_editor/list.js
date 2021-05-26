import React, { useState, useEffect } from 'react'

function List({collection}) {
  // set intial state
  const [ features, setFeatures ] = useState([])

  // initialization - retrieve GeoJSON features from Mock JSON API get features from mock
  //  GeoJson API (read from flat .json file in public directory)
  useEffect( () => {

  },[])

  return (
    <div className="list">
      <ul>
        {collection.map((item, i) => <li key={i}>{item.values_.name}</li>)}
      </ul>
    </div>
  )
}

export default List
