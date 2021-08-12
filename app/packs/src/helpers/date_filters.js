export default function DateFilter(buttonId, message, ...inputIds) {
  this.button = document.getElementById(buttonId)
  this.inputIds = inputIds
  this.message = message

  const getVal = (str, key) => {
    let newStr = str.replace(/NUM/, key)
    return document.getElementById(newStr).value
  }

  const getDates = () => {
    return this.inputIds.reduce((arr, id) => {
      let newIds = [1, 2, 3].map(key => getVal(id, key))
      arr.push(...newIds)
      return arr
    }, [])
  }

  const allInputFilled = () => getDates().every(date => !!date)

  const noInputFilled = () => getDates().every(date => !date)
  
  this.button && this.button.addEventListener('click', (event) => {
    if (!allInputFilled() && !noInputFilled()) {
      event.preventDefault()
      alert(this.message)
    }
  })
}