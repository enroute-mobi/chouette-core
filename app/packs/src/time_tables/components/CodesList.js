import React, { Component } from 'react'
import PropTypes from 'prop-types'
import _ from 'lodash'
import shortid from 'shortid'

export default class CodesList extends Component {
  constructor(props) {
    super(props)
  }

  handleAddCode() {
    this.props.onAddCode({
      id: null,
      code_space_id: window.available_code_spaces[0].id,
      value: "",
      fallback_id: shortid.generate()
    })
  }

  handleUpdateCodeSpace(e, code, index) {
    this.props.onUpdateCode({ code_space_id: e.target.value, value: code.value,  index: index })
    this.setState({codeValues: this.props.codeValues})
  }

  handleUpdateCodeValue(e, code, index) {
    this.props.onUpdateCode({ code_space_id: code.code_space_id, value: e.target.value,  index: index })
    this.setState({codeValues: this.props.codeValues})
  }

  handleRemoveCode(index) {
    this.props.onDeleteCode(index)
    this.setState({codeValues: this.props.codeValues})
  }

  render() {
    this.state = {codeValues: this.props.codeValues}

    return (
      <div className="container-fluid">
        <div className="row">
          <div className="col xs-9 col-xs-offset-3">
            <div className="definition-list">
              <h2>Codes</h2>

              {this.state.codeValues.map((codeData, index) => (
                <div key={codeData.id || codeData.fallback_id} className="row mb-2">
                  <div className="col-sm-4">
                    <select
                      className="form-control"
                      value={codeData.code_space_id}
                      onChange={(e) => {this.handleUpdateCodeSpace(e, codeData, index)}}
                    >
                      {window.available_code_spaces.map((code_space) =>
                        <option key={code_space.id} value={code_space.id}>
                          {code_space.short_name}
                        </option>
                      )}
                    </select>
                  </div>
                  <div className="col-sm-4">
                    <input
                      type="text"
                      className="form-control"
                      value={codeData.value}
                      onChange={(e) => {this.handleUpdateCodeValue(e, codeData, index)}}
                    />
                    { codeData.value === '' &&
                      <div><i className='fa fa-triangle-exclamation' /></div>
                    }
                  </div>

                  <div className="col-sm-2">
                    <button className="btn btn-danger" onClick={() => this.handleRemoveCode(index)}>
                      <i className='fa fa-trash'></i> {I18n.t('actions.delete')}
                    </button>
                  </div>
                </div>
              ))}

              <div className="row mb-2">
                <div className="col-sm-4"></div>
                <div className="col-sm-4"></div>
                <div className="col-sm-2">
                  <button
                    className="btn btn-primary pull-right"
                    onClick={() => {this.handleAddCode()}}
                  >
                    {I18n.t('time_tables.actions.add_code')}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }
}

CodesList.propTypes = {
  codeValues: PropTypes.array.isRequired,
  onAddCode: PropTypes.func.isRequired,
  onUpdateCode: PropTypes.func.isRequired,
  onDeleteCode: PropTypes.func.isRequired
}
