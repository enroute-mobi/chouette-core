import React, { PropTypes, Component } from 'react'
import { bindAll } from 'lodash'

export default class SaveButton extends Component{
  constructor(props){
    super(props)

    bindAll(this, 'handleClick')
  }

  btnDisabled(){
    return !this.props.status.fetchSuccess || this.props.status.isFetching
  }

  btnClass(){
    let className = ['btn btn-default']
    if(this.btnDisabled()){
      className.push('disabled')
    }
    return className.join(' ')
  }

  handleClick(e) {
    e.preventDefault()
    this.props.editMode ? this.submitForm() : this.props.onEnterEditMode()
  }

  render() {
    if (!this.hasPolicy()) {
      return false
    }else{
      return (
        <div className='row mt-md'>
          <div className='col-lg-12 text-right'>
            <form className={this.formClassName() + ' formSubmitr ml-xs'} onSubmit={e => {e.preventDefault()}}>
              <div className="btn-group sticky-actions">
                <button
                  className={this.btnClass()}
                  type='button'
                  disabled={this.btnDisabled()}
                  onClick={this.handleClick}
                >
                  {this.props.editMode ? I18n.t('actions.submit') : I18n.t('actions.edit')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )
    }
  }
}

SaveButton.defaultProps = {
  status: {
    fetchSuccess: false,
    isFetching: false
  }
}
