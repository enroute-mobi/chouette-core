import React, { Component } from 'react'
import PropTypes from 'prop-types'

export default class CodesList extends Component {
  constructor(props) {
    super(props)
    this.state = {
      newCode: '',
      selectedCodeSpace: 'external'
    }
  }

  render() {
    const { codes = [], onAddCode, onUpdateCode, onDeleteCode } = this.props

    const handleAddCode = () => {
      if (this.state.newCode.trim() !== '') {
        onAddCode({ code: this.state.newCode, codeSpace: this.state.selectedCodeSpace })
        this.setState({ newCode: '' })
      }
    }

    const handleUpdateCode = (index, updatedCode) => {
      onUpdateCode(index, updatedCode)
    }

    const handleRemoveCode = (index) => {
      onDeleteCode(index)
    }

    return (
      <div className="container-fluid">
        <div className="row">
          <div className="col xs-9 col-xs-offset-3">
            <div className="definition-list">
              <h2>Codes</h2>
              <div className="row mb-3">
                <div className="col-sm-4">
                  <select
                    className="form-control"
                    value={this.state.selectedCodeSpace}
                    onChange={(e) => this.setState({ selectedCodeSpace: e.target.value })}
                  >
                    <option value="external">Externe</option>
                    <option value="national">National</option>
                    <option value="public">Public</option>
                  </select>
                </div>
                <div className="col-sm-4">
                  <input
                    type="text"
                    className="form-control"
                    value={this.state.newCode}
                    onChange={(e) => this.setState({ newCode: e.target.value })}
                    placeholder="Nouveau code"
                  />
                </div>
                <div className="col-sm-2">
                  <button
                    className="btn btn-primary"
                    onClick={handleAddCode}
                    disabled={this.state.newCode.trim() === ''}
                  >
                    Ajouter un code
                  </button>
                </div>
              </div>
              {codes.map((codeData, index) => (
                <div key={index} className="row mb-2">
                  <div className="col-sm-4">
                    <select
                      className="form-control"
                      value={codeData ? codeData.codeSpace : ''}
                      onChange={(e) => handleUpdateCode(index, { ...codeData, codeSpace: e.target.value })}
                      disabled
                    >
                      <option value="external">Externe</option>
                      <option value="national">National</option>
                      <option value="public">Public</option>
                    </select>
                  </div>
                  <div className="col-sm-4">
                    <input
                      type="text"
                      className="form-control"
                      value={codeData ? codeData.code : ''}
                      onChange={(e) => handleUpdateCode(index, { ...codeData, code: e.target.value })}
                      disabled
                    />
                  </div>
                  <div className="col-sm-2">
                    <button className="btn btn-danger" onClick={() => handleRemoveCode(index)}>
                      <i className="fa fa-trash" aria-hidden="true"></i> Supprimer
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    )
  }
}

CodesList.propTypes = {
  codes: PropTypes.array.isRequired,
  onAddCode: PropTypes.func.isRequired,
  onUpdateCode: PropTypes.func.isRequired,
  onDeleteCode: PropTypes.func.isRequired
}
