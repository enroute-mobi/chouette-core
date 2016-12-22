var React = require('react')
var PropTypes = require('react').PropTypes
var Select2 = require('react-select2')


// get JSON full path
var origin = window.location.origin
var path = window.location.pathname.split('/', 3).join('/')


class BSelect3 extends React.Component{
  constructor(props) {
    super(props)
    this.state = {
      edit: false
    }
  }
  onToggleEdit(e) {
    e.preventDefault()
    this.setState({edit: !this.state.edit})
  }
  onChange(e) {
    this.props.onChange(this.props.index, {
      text: e.currentTarget.textContent,
      stoparea_id: e.currentTarget.value,
      user_objectid: e.params.data.user_objectid
    })
    this.setState({edit: false})
  }

  render() {
    if(this.state.edit)
      return (
        <div className='input-group select2-bootstrap-append'>
          <BSelect2 {...this.props} onSelect={ this.onChange.bind(this) }/>

          <span className='input-group-btn'>
            <button type='button' className='btn btn-default' onClick={this.onToggleEdit.bind(this)}>
              <span className='fa fa-undo'></span>
            </button>
          </span>
        </div>
      )
    else
      if(!this.props.value.stoparea_id)
        return (
          <div>
            <BSelect2 {...this.props} onSelect={ this.onChange.bind(this) }/>
          </div>
        )
      else
        return (
          <div className='input-group'>
            <a
              className='form-control form-control-link'
              href={origin + path + '/stop_areas/' + this.props.value.stoparea_id}
              title={"Voir l'arrêt '" + this.props.value.text + "'"}
              style={{lineHeight: '22px', overflow: 'hidden'}}
            >
              {this.props.value.text}
            </a>
            <span className='input-group-btn'>
              <button type='button' className='btn btn-default' onClick={this.onToggleEdit.bind(this)}>
                <span className='fa fa-pencil'></span>
              </button>
            </span>
          </div>
        )
  }
}

class BSelect2 extends React.Component{
  componentDidMount() {
    this.refs.newSelect.el.select2('open')
  }

  render() {
    return (
      <Select2
        value={ this.props.value.stoparea_id }
        onSelect={ this.props.onSelect }
        ref='newSelect'
        options={{
          placeholder: 'Sélectionnez un arrêt existant...',
          allowClear: true,
          language: 'fr', /* Doesn't seem to work... :( */
          theme: 'bootstrap',
          width: '100%',
          ajax: {
            url: origin + path + '/autocomplete_stop_areas.json',
            dataType: 'json',
            delay: '500',
            data: function(params) {
              return {
                q: params.term,
                target_type: 'zdep'
              };
            },
            processResults: function(data, params) {
              return {
                results: data.map(
                  item => Object.assign(
                    {},
                    item,
                    { text: item.name + ", " + item.zip_code + " " + item.short_city_name }
                  )
                )
              };
            },
            cache: true
          },
          minimumInputLength: 3,
          templateResult: formatRepo
        }}
      />
    )
  }
}

const formatRepo = (props) => {
  if(props.text) return props.text
  // console.log(props)
  // return (
  //   <div>
  //     {props.short_name}
  //     <small><em>{props.zip_code} {props.short_city_name}</em></small>
  //   </div>
  // )
}

module.exports = BSelect3
