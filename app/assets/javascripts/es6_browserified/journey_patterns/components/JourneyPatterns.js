var React = require('react')
var Component = require('react').Component
var PropTypes = require('react').PropTypes
var JourneyPattern = require('./JourneyPattern')
var _ = require('lodash')

class JourneyPatterns extends Component{
  constructor(props){
    super(props)
    this.previousCity = undefined
  }
  componentDidMount() {
    this.props.onLoadFirstPage()
  }
  componentDidUpdate(prevProps, prevState) {
    if(this.props.status.isFetching == false){
      $('.table-2entries').each(function() {
        var refH = []
        var refCol = []

        $(this).find('.t2e-head').children('div').each(function() {
          var h = $(this).outerHeight();
          refH.push(h)
        });

        var i = 0
        $(this).find('.t2e-item').children('div').each(function() {
          var h = $(this).outerHeight();
          if(refCol.length < refH.length){
            refCol.push(h)
          } else {
            if(h > refCol[i]) {
              refCol[i] = h
            }
          }
          if(i == (refH.length - 1)){
            i = 0
          } else {
            i++
          }
        });

        for(var n = 0; n < refH.length; n++) {
          if(refCol[n] < refH[n]) {
            refCol[n] = refH[n]
          }
        }

        $(this).find('.th').css('height', refCol[0]);

        for(var nth = 1; nth < refH.length; nth++) {
          $(this).find('.td:nth-child('+ (nth + 1) +')').css('height', refCol[nth]);
        }
      });
    }
  }

  cityNameChecker(sp) {
    let bool = false
    if(sp.city_name != this.previousCity){
      bool = true
      this.previousCity = sp.city_name
    }
    return (
      <div
        className={(bool) ? 'headlined' : ''}
        data-headline={(bool) ? sp.city_name : ''}
        title={sp.city_name + ' (' + sp.zip_code +')'}
      >
        <span><span>{sp.name}</span></span>
      </div>
    )
  }

  render() {
    this.previousCity = undefined

    if(this.props.status.isFetching == true) {
      return (
        <div className="isLoading" style={{marginTop: 80, marginBottom: 80}}>
          <div className="loader"></div>
        </div>
      )
    } else {
      return (
        <div className='row'>
          <div className='col-lg-12'>
            {(this.props.status.fetchSuccess == false) && (
              <div className="alert alert-danger mt-sm">
                <strong>Erreur : </strong>
                la récupération des missions a rencontré un problème. Rechargez la page pour tenter de corriger le problème
              </div>
            )}

            { _.some(this.props.journeyPatterns, 'errors') && (
              <div className="alert alert-danger mt-sm">
                <strong>Erreur : </strong>
                {this.props.journeyPatterns.map((jp, index) =>
                  jp.errors.map((err, i) => {
                    return (
                      <ul key={i}>
                        <li>{err}</li>
                      </ul>
                    )
                  })
                )}
              </div>
            )}

            <div className={'table table-2entries mt-sm mb-sm' + ((this.props.journeyPatterns.length > 0) ? '' : ' no_result')}>
              <div className='t2e-head w20'>
                <div className='th'>
                  <div className='strong mb-xs'>ID Mission</div>
                  <div>Code mission</div>
                  <div>Nb arrêts</div>
                </div>
                {this.props.stopPointsList.map((sp, i) =>{
                  return (
                    <div key={i} className='td'>
                      {this.cityNameChecker(sp)}
                    </div>
                  )
                })}
              </div>

              <div className='t2e-item-list w80'>
                <div>
                  {this.props.journeyPatterns.map((journeyPattern, index) =>
                    <JourneyPattern
                      value={ journeyPattern }
                      key={ index }
                      onCheckboxChange= {(e) => this.props.onCheckboxChange(e, index)}
                      onOpenEditModal= {() => this.props.onOpenEditModal(index, journeyPattern)}
                      onDeleteJourneyPattern={() => this.props.onDeleteJourneyPattern(index)}
                      status= {this.props.status}
                      editMode= {this.props.editMode}
                      />
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      )
    }
  }
}

JourneyPatterns.propTypes = {
  journeyPatterns: PropTypes.array.isRequired,
  stopPointsList: PropTypes.array.isRequired,
  status: PropTypes.object.isRequired,
  onCheckboxChange: PropTypes.func.isRequired,
  onLoadFirstPage: PropTypes.func.isRequired,
  onOpenEditModal: PropTypes.func.isRequired
}

module.exports = JourneyPatterns
