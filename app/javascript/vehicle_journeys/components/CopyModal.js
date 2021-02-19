import React, { Component } from 'react'
import PropTypes from 'prop-types'
import ClipboardHelper from '../helpers/ClipboardHelper'

export default class CopyModal extends Component {
  constructor(props) {
    super(props)
    this.updateContent = this.updateContent.bind(this)
    this.selectAll = this.selectAll.bind(this)
    this.pasteFromClipboard = this.pasteFromClipboard.bind(this)
    this.onKeyDown = this.onKeyDown.bind(this)
  }

  renderCopyContent() {
    const { items, width, toggleArrivals } = this.props

    return ClipboardHelper.copy(items, width, toggleArrivals)
  }

  updateContent() {
    this.props.updateContent(this.refs.pasteContent.value)
  }

  selectAll() {
    if (document.body.createTextRange) { // ms
      var range = document.body.createTextRange();
      range.moveToElementText(this.refs.copyContent);
      range.select();
    } else if (window.getSelection) { // moz, opera, webkit
      var selection = window.getSelection();
      var range = document.createRange();
      range.selectNodeContents(this.refs.copyContent);
      selection.removeAllRanges();
      selection.addRange(range);
    }
  }

  onKeyDown(event) {
    if(!this.props.visible){ return }

    if(this.props.mode == 'copy' && event.key == "a" && (event.metaKey || event.ctrlKey)){
      event.stopImmediatePropagation()
      event.preventDefault()
      this.selectAll()
      return false
    }
  }

  pasteFromClipboardAvailable() {
    return !! (navigator.clipboard && navigator.clipboard.readText)
  }

  pasteFromClipboard() {
    let self = this
    navigator.clipboard.readText().then(function(clipText){
      self.props.updateContent(clipText)
    }).catch(function(err){ console.log(err) })
  }


  componentDidUpdate(prevProps, prevState) {
    if(this.props.visible){
      if(this.props.mode == 'copy'){
        this.selectAll()
      }
      else {
        this.refs.pasteContent.focus()
      }
    }
    document.addEventListener("keydown", this.onKeyDown)
  }

  render() {
    const { visible } = this.props

    if (!visible) return false
    
    return (
      <div>
        <div className={'modal fade ' + (this.props.visible ? 'in' : '')} style={{ display: (this.props.visible ? 'block' : 'none') }} id='CopyModal'>
          <div className='modal-container'>
            <div className='modal-dialog'>
              <div className='modal-content'>
                <div className='modal-header'>
                  <i className='fa fa-paste'></i>
                  <span>{ I18n.t('courses_copy_paste.modal.head') }</span>
                  <span type="button" className="close modal-close" onClick={this.props.closeModal}>&times;</span>
                </div>
                <div className='modal-body'>
                  {this.props.error && <div className='alert alert-danger'>
                    { I18n.t('courses_copy_paste.errors.' + this.props.error) }
                  </div>}
                  {this.props.mode == 'copy' && <div>
                    <pre ref='copyContent'>{this.renderCopyContent()}</pre>
                  </div>}
                  {this.props.mode == 'paste' && <div>
                    <textarea
                      ref='pasteContent'
                      onChange={this.updateContent}
                      value={this.props.content}
                    />
                    {this.pasteFromClipboardAvailable() && <button
                      className="btn btn-default pull-right"
                      onClick={this.pasteFromClipboard}>
                        { I18n.t('courses_copy_paste.modal.paste_from_clipboard') }
                    </button>}
                    <br/>
                  </div>}
                </div>
                <div className='modal-footer'>
                <button
                  className="btn btn-link"
                  onClick={this.props.closeModal}>
                    {I18n.t('cancel')}
                </button>
                {this.props.mode == 'copy' && <button
                  className='btn btn-primary'
                  onClick={this.props.toPasteMode}>
                    <i className='fa fa-paste'></i>
                    <span>{ I18n.t('courses_copy_paste.modal.to_paste_mode') }</span>
                </button>}
                {this.props.mode == 'paste' && !this.props.paste_only && <button
                  className='btn btn-default'
                  onClick={this.props.toCopyMode}>
                    <i className='fa fa-caret-left'></i>
                    <span>{ I18n.t('courses_copy_paste.modal.to_copy_mode') }</span>
                </button>}
                {this.props.mode == 'paste' && <button
                  className='btn btn-primary'
                  disabled={!!this.props.error}
                  onClick={this.props.pasteContent}>
                    <i className='fa fa-paste'></i>
                    <span>{ I18n.t('courses_copy_paste.modal.paste_content') }</span>
                </button>}
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className={'modal-backdrop fade ' + (this.props.visible ? 'in' : '')} style={{ display: (this.props.visible ? 'block' : 'none') }}/>
      </div>
    )
  }
}

CopyModal.propTypes = {
  visible: PropTypes.bool.isRequired
}
