class FlashMessage extends Component{

  render(){
    const {message, className} = this.props.flashMessage;
    if(!message){
      return null;
    }

    return (
      <div className="row mt-md">
        <div 
        className={'col-md-12 alert ' + className} 
        role="alert">
          {message}
        </div>
      </div>
    );
  }
}