import React, { useRef, useEffect } from 'react'
import PropTypes from 'prop-types'

import { useDebounce } from '../../helpers/hooks'
import { CopyContent, PasteContent } from '../helpers/ClipboardHelper'

const CopyModal = props => {
  const copyContentRef = useRef(null)
  const pasteContentRef = useRef(null)

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
  } = props

  const updatePasteContent = useDebounce(
    props.updatePasteContent,
    200
  )

  const selectAll = () => {
    if (document.body.createTextRange) { // ms
      const range = document.body.createTextRange();
      range.moveToElementText(copyContentRef.current);
      range.select();
    } else if (window.getSelection) { // moz, opera, webkit
      const selection = window.getSelection();
      const range = document.createRange();
      range.selectNodeContents(copyContentRef.current);
      selection.removeAllRanges();
      selection.addRange(range);
    }
  }

  const onKeyDown = event => {
    if (!visible) return

    if(mode == 'copy' && event.key == "a" && (event.metaKey || event.ctrlKey)){
      event.stopImmediatePropagation()
      event.preventDefault()
      selectAll()
      return false
    }
  }

  const pasteFromClipboardAvailable = () =>
    !!(navigator.clipboard && navigator.clipboard.readText)


  const pasteFromClipboard = async () => {
    try {
      const clipText = await navigator.clipboard.readText()
      props.updatePasteContent(clipText)
    } catch(e) {
      console.error(e)
    }
  }

  useEffect(() => {
    if (visible){
      mode == 'copy' ? selectAll() : pasteContentRef.current.focus()
    }

    document.addEventListener("keydown", onKeyDown)
  })

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
                  <pre ref={copyContentRef}>{content.copy}</pre>
                </div>}
                {mode == 'paste' && <div>
                  <textarea
                    ref={pasteContentRef}
                    onPaste={e => updatePasteContent(e.clipboardData.getData('text'))}
                    onChange={e => updatePasteContent(e.target.value)}
                    wrap="off"
                  >
                    {content.paste}
                  </textarea>
                  {pasteFromClipboardAvailable() && <button
                    className="btn btn-default pull-right"
                    onClick={pasteFromClipboard}>
                      { I18n.t('courses_copy_paste.modal.paste_from_clipboard') }
                  </button>}
                  <br/>
                </div>}
              </div>
              <div className='modal-footer'>
              <button
                className="btn btn-cancel"
                onClick={closeModal}>
                  {I18n.t('cancel')}
              </button>
              {mode == 'copy' && <button
                className='btn btn-default'
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
                className='btn btn-default'
                disabled={!!error || !content.paste}
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

CopyModal.propTypes = {
  visible: PropTypes.bool.isRequired,
  mode: PropTypes.oneOf(['copy', 'paste']),
  error: PropTypes.string,
  content: {
    copy: PropTypes.instanceOf(CopyContent),
    paste: PropTypes.instanceOf(PasteContent),
  }
}

export default CopyModal
