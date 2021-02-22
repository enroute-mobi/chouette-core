import React, { Component } from 'react'
import PropTypes from 'prop-types'
import autoBind from 'react-autobind'
import { CopyContent, PasteContent } from '../helpers/ClipboardHelper'

export default class CopyModal extends Component {
  constructor(props) {
    super(props)

    autoBind(this)
  }

  updatePasteContent() {
    this.props.updatePasteContent(this.refs.pasteContent.value)
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
      self.props.updatePasteContent(clipText)
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
    const {
      closeModal,
      content,
      error,
      mode,
      pasteContent,
      pasteOnly,
      toCopyMode,
      toPasteMode,
      visible
    } = this.props

    if (!visible) return false

    return (
      <div>
        <div className={'modal fade ' + (visible ? 'in' : '')} style={{ display: (visible ? 'block' : 'none') }} id='CopyModal'>
          <div className='modal-container'>
            <div className='modal-dialog'>
              <div className='modal-content'>
                <div className='modal-header'>
                  <i className='fa fa-paste'></i>
                  <span>{ I18n.t('courses_copy_paste.modal.head') }</span>
                  <span type="button" className="close modal-close" onClick={closeModal}>&times;</span>
                </div>
                <div className='modal-body'>
                  {error && <div className='alert alert-danger'>
                    { I18n.t('courses_copy_paste.errors.' + error) }
                  </div>}
                  {mode == 'copy' && <div>
                    <pre ref='copyContent'>{content.copy}</pre>
                  </div>}
                  {mode == 'paste' && <div>
                    <textarea
                      ref='pasteContent'
                      onChange={this.updatePasteContent}
                      value={content.paste}
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
                  onClick={closeModal}>
                    {I18n.t('cancel')}
                </button>
                {mode == 'copy' && <button
                  className='btn btn-primary'
                  onClick={toPasteMode}>
                    <i className='fa fa-paste'></i>
                    <span>{ I18n.t('courses_copy_paste.modal.to_paste_mode') }</span>
                </button>}
                {mode == 'paste' && !pasteOnly && <button
                  className='btn btn-default'
                    onClick={toCopyMode}>
                    <i className='fa fa-caret-left'></i>
                    <span>{ I18n.t('courses_copy_paste.modal.to_copy_mode') }</span>
                </button>}
                {mode == 'paste' && <button
                  className='btn btn-primary'
                  disabled={!!error}
                  onClick={pasteContent}>
                    <i className='fa fa-paste'></i>
                    <span>{ I18n.t('courses_copy_paste.modal.paste_content') }</span>
                </button>}
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className={'modal-backdrop fade ' + (visible ? 'in' : '')} style={{ display: (visible ? 'block' : 'none') }}/>
      </div>
    )
  }
}

CopyModal.propTypes = {
  visible: PropTypes.bool.isRequired,
  mode: PropTypes.oneOf(['copy', 'paste']),
  error: PropTypes.string,
  content: {
    copy: PropTypes.instanceOf(CopyContent),
    paste: PropTypes.instanceOf(PasteContent),
  }
}
